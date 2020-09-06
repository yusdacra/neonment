use super::{
    Delivery, DeliveryAddress, Events, NetworkConnectionInfo, NetworkDelivery, NetworkResource,
    Res, ResMut,
};

pub struct SendEvent(Delivery);
impl SendEvent {
    pub fn new(del: Delivery) -> Self {
        SendEvent(del)
    }
}

pub type SendEvents = Events<SendEvent>;

pub(crate) fn deliver(
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
