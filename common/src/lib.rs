use bevy::prelude::*;
use bevy_prototype_networking_laminar::{
    Connection, NetworkDelivery, NetworkError as LowLevelNetworkError,
    NetworkEvent as LowLevelNetworkingEvent, NetworkResource, NetworkingPlugin,
};
use bytes::Bytes;
use std::net::SocketAddr;

pub use bincode::deserialize;
pub use serde::{Deserialize, Serialize};
pub use std::net::AddrParseError;

use bevy::math::Vec2;
#[derive(Debug, Serialize, Deserialize)]
pub enum NetworkTypes {
    TestType { pos: Vec2, rot: f64 },
    Message(String),
}

pub struct NetworkPlugin;

impl Plugin for NetworkPlugin {
    fn build(&self, app: &mut AppBuilder) {
        app.add_plugin(NetworkingPlugin)
            .add_event::<NetworkEvent>()
            .add_event::<SendEvent>()
            .init_resource::<NetworkConnectionInfo>()
            .init_resource::<LowLevelNetworkEventReader>()
            .init_resource::<NetworkManager>()
            .add_system(control_networking.system())
            .add_system(poll_low_level_network_events.system())
            .add_system(deliver.system());
    }
}

#[derive(Default, Debug, Copy, Clone)]
pub struct NetworkConnectionInfo {
    bind_addr: Option<SocketAddr>,
    server_addr: Option<SocketAddr>,
}

impl NetworkConnectionInfo {
    pub fn client(&mut self, addr: &str, server_addr: &str) -> Result<(), NetworkError> {
        self.bind_addr = Some(addr.parse()?);
        self.server_addr = Some(server_addr.parse()?);
        Ok(())
    }

    pub fn server(&mut self, addr: &str) -> Result<(), NetworkError> {
        self.bind_addr = Some(addr.parse()?);
        self.server_addr = None;
        Ok(())
    }

    pub fn clear(&mut self) {
        self.bind_addr = None;
        self.server_addr = None;
    }

    pub fn is_server(&self) -> bool {
        self.server_addr.is_none()
    }

    pub fn is_client(&self) -> bool {
        self.server_addr.is_some()
    }
}

#[derive(Debug)]
enum DeliveryAddress {
    To(SocketAddr),
    From(SocketAddr),
    Broadcast,
}

#[derive(Debug, Serialize, Deserialize)]
struct Payload {
    data: Bytes,
    is_reliable: bool,
    is_compressed: bool,
}

impl Payload {
    fn new(data: Bytes) -> Self {
        Self {
            data,
            is_reliable: false,
            is_compressed: false,
        }
    }
}

#[derive(Debug)]
pub struct Delivery {
    addr: DeliveryAddress,
    payload: Payload,
}

impl Into<SendEvent> for Delivery {
    fn into(self) -> SendEvent {
        SendEvent(self)
    }
}

impl Delivery {
    pub fn new(data: &impl Serialize) -> Result<Self, NetworkError> {
        Ok(Self {
            addr: DeliveryAddress::Broadcast,
            payload: Payload::new(bincode::serialize(data)?.into()),
        })
    }

    pub fn send_to(data: &impl Serialize, addr: SocketAddr) -> Result<Self, NetworkError> {
        Ok(Self {
            addr: DeliveryAddress::To(addr),
            payload: Payload::new(bincode::serialize(data)?.into()),
        })
    }

    pub(crate) fn from(payload: Payload, addr: SocketAddr) -> Self {
        Self {
            addr: DeliveryAddress::From(addr),
            payload,
        }
    }

    pub fn reliable(mut self) -> Self {
        self.payload.is_reliable = true;
        self
    }

    pub fn compress(mut self) -> Result<Self, NetworkError> {
        if self.payload.is_compressed {
            return Err(NetworkError::AlreadyCompressed);
        }

        self.payload.data = lz4::block::compress(
            &self.payload.data,
            Some(lz4::block::CompressionMode::HIGHCOMPRESSION(21)), // 2 MB memory usage
            true,
        )?
        .into();

        self.payload.is_compressed = true;

        Ok(self)
    }

    pub fn compress_if_worth_it(self) -> Result<Self, NetworkError> {
        let before_data = self.payload.data.clone();
        let mut compressed = self.compress()?;

        if compressed.payload.data.len() >= before_data.len() {
            compressed.payload.data = before_data;
            compressed.payload.is_compressed = false;
        }

        Ok(compressed)
    }

    pub fn data(self) -> Result<Bytes, NetworkError> {
        if self.payload.is_compressed {
            lz4::block::decompress(&self.payload.data, None)
                .map_or_else(|e| Err(e.into()), |v| Ok(v.into()))
        } else {
            Ok(self.payload.data)
        }
    }
}

#[derive(Debug)]
pub enum NetworkError {
    Addr(AddrParseError),
    Parse(bincode::ErrorKind),
    Compression(std::io::Error),
    AlreadyCompressed,
}

impl From<Box<bincode::ErrorKind>> for NetworkError {
    fn from(other: Box<bincode::ErrorKind>) -> Self {
        NetworkError::Parse(*other)
    }
}

impl From<std::io::Error> for NetworkError {
    fn from(other: std::io::Error) -> Self {
        NetworkError::Compression(other)
    }
}

impl From<AddrParseError> for NetworkError {
    fn from(other: AddrParseError) -> Self {
        NetworkError::Addr(other)
    }
}

#[derive(Debug)]
pub enum NetworkEvent {
    Received(Delivery),
    Error(NetworkError),
    Connection(ConnectionEvent),
}
pub type NetworkEvents = Events<NetworkEvent>;

pub struct SendEvent(Delivery);
pub type SendEvents = Events<SendEvent>;

#[derive(Debug)]
pub enum ConnectionEvent {
    Disconnected(Connection),
    Connected(Connection),
}

#[derive(Default)]
struct NetworkManager {
    is_bound: bool,
}

#[derive(Default)]
struct LowLevelNetworkEventReader {
    network_events: EventReader<LowLevelNetworkingEvent>,
}

fn control_networking(
    con_info: Res<NetworkConnectionInfo>,
    mut net_res: ResMut<NetworkResource>,
    mut net: ResMut<NetworkManager>,
) {
    if let Some(addr) = con_info.bind_addr {
        if !net.is_bound {
            if let Err(err) = net_res.bind(addr) {
                if let LowLevelNetworkError::IOError(errr) = err {
                    if errr.kind() == std::io::ErrorKind::AddrInUse {
                        return;
                    }
                } else {
                    eprintln!("Could not bind to socket: {}", err);
                }
                return;
            };
            net.is_bound = true;
        } else {
            return;
        }
    } else {
        if net.is_bound {
            // FIXME: Handle socket unbinding here
            net.is_bound = false;
        } else {
            return;
        }
    }
}

fn deliver(
    con_info: Res<NetworkConnectionInfo>,
    net_res: Res<NetworkResource>,
    mut send_events: ResMut<Events<SendEvent>>,
) {
    for ev in send_events.drain() {
        let del_mode = if ev.0.payload.is_reliable {
            NetworkDelivery::ReliableUnordered
        } else {
            NetworkDelivery::UnreliableUnordered
        };
        let payload_bin = bincode::serialize(&ev.0.payload).unwrap();
        if let Some(server_addr) = con_info.server_addr {
            // FIXME: Handle errors?
            if let Err(err) = net_res.send(server_addr, &payload_bin, del_mode) {
                eprintln!("Could not send delivery: {}", err);
                continue;
            }
        } else if !net_res.connections().is_empty() {
            match ev.0.addr {
                DeliveryAddress::Broadcast => {
                    // FIXME: Handle errors?
                    if let Err(err) = net_res.broadcast(&payload_bin, del_mode) {
                        eprintln!("Could not send delivery: {}", err);
                        continue;
                    }
                }
                DeliveryAddress::To(addr) => {
                    // FIXME: Handle errors?
                    if let Err(err) = net_res.send(addr, &payload_bin, del_mode) {
                        eprintln!("Could not send delivery: {}", err);
                        continue;
                    }
                }
                _ => {
                    unreachable!("A delivery address can't be set to `From` using the public API!");
                }
            }
        }
    }
}

fn poll_low_level_network_events(
    lownet_events: Res<Events<LowLevelNetworkingEvent>>,
    mut lownet_event_state: ResMut<LowLevelNetworkEventReader>,
    mut network_events: ResMut<Events<NetworkEvent>>,
) {
    for ev in lownet_event_state.network_events.iter(&lownet_events) {
        match ev {
            LowLevelNetworkingEvent::Message(con, data) => {
                network_events.send(NetworkEvent::Received(Delivery::from(
                    match bincode::deserialize(&data) {
                        Err(err) => {
                            network_events.send(NetworkEvent::Error(err.into()));
                            continue;
                        }
                        Ok(p) => p,
                    },
                    con.addr,
                )))
            }
            LowLevelNetworkingEvent::Disconnected(con) => {
                network_events.send(NetworkEvent::Connection(ConnectionEvent::Disconnected(
                    *con,
                )));
            }
            LowLevelNetworkingEvent::Connected(con) => {
                network_events.send(NetworkEvent::Connection(ConnectionEvent::Connected(*con)));
            }
            // FIXME: Handle errors?
            LowLevelNetworkingEvent::SendError(err) => eprintln!("{}", err),
        }
    }
}
