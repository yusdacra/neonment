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
        app.add_event::<NetworkEvent>()
            .add_plugin(NetworkingPlugin)
            .init_resource::<NetworkConnectionInfo>()
            .init_resource::<LowLevelNetworkEventReader>()
            .add_resource(NetworkManager::new())
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
    Delivery(Delivery),
    NetworkError(NetworkError),
    Connection(ConnectionEvent),
}

#[derive(Debug)]
pub enum ConnectionEvent {
    Disconnected(Connection),
    Connected(Connection),
}

pub struct NetworkManager {
    is_bound: bool,
    send_queue: Vec<Delivery>,
    send_queue_reliable: Vec<Delivery>,
    con_event_queue: Vec<ConnectionEvent>,
}

impl NetworkManager {
    pub fn new() -> Self {
        Self {
            is_bound: false,
            send_queue: Vec::new(),
            send_queue_reliable: Vec::new(),
            con_event_queue: Vec::new(),
        }
    }

    pub fn send(&mut self, delivery: Delivery) {
        self.send_queue.push(delivery);
    }

    pub fn send_reliable(&mut self, delivery: Delivery) {
        self.send_queue_reliable.push(delivery);
    }
}

#[derive(Default)]
struct LowLevelNetworkEventReader {
    network_events: EventReader<LowLevelNetworkingEvent>,
}

fn control_networking(
    con_info: Res<NetworkConnectionInfo>,
    mut net: ResMut<NetworkManager>,
    mut net_res: ResMut<NetworkResource>,
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
            // Clean everything up except, because these are invalidated
            net.send_queue.clear();
            net.send_queue_reliable.clear();
            net.con_event_queue.clear();
            net.is_bound = true;
        } else {
            return;
        }
    } else {
        if net.is_bound {
            // Clean everything up except, because these are invalidated
            // FIXME: Handle socket unbinding here
            net.send_queue.clear();
            net.send_queue_reliable.clear();
            net.con_event_queue.clear();
            net.is_bound = false;
        } else {
            return;
        }
    }
}

fn deliver(
    con_info: Res<NetworkConnectionInfo>,
    net_res: Res<NetworkResource>,
    mut dvs: ResMut<NetworkManager>,
) {
    send_queue_loop(
        &con_info,
        &net_res,
        &mut dvs.send_queue,
        NetworkDelivery::UnreliableUnordered,
    );

    send_queue_loop(
        &con_info,
        &net_res,
        &mut dvs.send_queue_reliable,
        NetworkDelivery::ReliableUnordered,
    );
}

fn poll_low_level_network_events(
    lownet_events: Res<Events<LowLevelNetworkingEvent>>,
    mut lownet_event_state: ResMut<LowLevelNetworkEventReader>,
    mut network_events: ResMut<Events<NetworkEvent>>,
) {
    for ev in lownet_event_state.network_events.iter(&lownet_events) {
        match ev {
            LowLevelNetworkingEvent::Message(con, data) => {
                network_events.send(NetworkEvent::Delivery(Delivery::from(
                    match bincode::deserialize(&data) {
                        Err(err) => {
                            network_events.send(NetworkEvent::NetworkError(err.into()));
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

fn send_queue_loop(
    con_info: &NetworkConnectionInfo,
    net_res: &NetworkResource,
    queue: &mut Vec<Delivery>,
    del_mode: NetworkDelivery,
) {
    for mut dv in queue.drain(..) {
        dv.payload.is_reliable = true;
        let payload_bin = bincode::serialize(&dv.payload).unwrap();
        if let Some(server_addr) = con_info.server_addr {
            // FIXME: Handle errors?
            if let Err(err) = net_res.send(server_addr, &payload_bin, del_mode) {
                eprintln!("Could not send delivery: {}", err);
                continue;
            }
        } else if !net_res.connections().is_empty() {
            match dv.addr {
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
