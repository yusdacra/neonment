use super::{
    ConnectionEvent, Delivery, EventReader, Events, LowLevelNetworkingEvent, NetworkError, Res,
    ResMut,
};

#[derive(Default)]
pub(crate) struct LowLevelNetworkEventReader {
    network_events: EventReader<LowLevelNetworkingEvent>,
}

#[derive(Debug)]
pub enum NetworkEvent {
    Received(Delivery),
    Error(NetworkError),
    Connection(ConnectionEvent),
}
pub type NetworkEvents = Events<NetworkEvent>;

pub(crate) fn poll_low_level_network_events(
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
