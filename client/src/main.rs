use bevy::prelude::*;
use common::{
    Delivery, NetworkConnectionInfo, NetworkEvent, NetworkEvents, NetworkPlugin, NetworkTypes,
    SendEvents,
};
use rand::prelude::*;

fn deser(del: Delivery) -> NetworkTypes {
    common::deserialize(&del.data().unwrap()).unwrap()
}

fn main() {
    App::build()
        .init_resource::<TimerState>()
        .init_resource::<UTimerState>()
        .add_default_plugins()
        .add_plugin(NetworkPlugin)
        .add_startup_system(setup.system())
        .add_system(send_delivery.system())
        .add_system(send_undelivery.system())
        .add_system(print_network_events.system())
        .run();
}

fn setup(mut con_info: ResMut<NetworkConnectionInfo>) {
    con_info.client("127.0.0.1:5554", "127.0.0.1:5555").unwrap();
}

fn print_network_events(mut netevents: ResMut<NetworkEvents>) {
    for ev in netevents.drain() {
        match ev {
            NetworkEvent::Received(del) => println!("{:?}", deser(del)),
            _ => println!("{:?}", ev),
        }
    }
}

struct TimerState {
    timer: Timer,
}

impl Default for TimerState {
    fn default() -> Self {
        Self {
            timer: Timer::from_seconds(1.0 / 60.0, true),
        }
    }
}

fn send_delivery(
    time: Res<Time>,
    mut timer: ResMut<TimerState>,
    mut send_events: ResMut<SendEvents>,
) {
    timer.timer.tick(time.delta_seconds);
    if timer.timer.finished {
        send_events.send(
            Delivery::new(&NetworkTypes::TestType {
                pos: Vec2::new(random(), random()),
                rot: random(),
            })
            .unwrap()
            .reliable()
            .compress_if_worth_it()
            .unwrap()
            .into(),
        );
        timer.timer.reset();
    }
}

struct UTimerState {
    timer: Timer,
}

impl Default for UTimerState {
    fn default() -> Self {
        Self {
            timer: Timer::from_seconds(30.0, true),
        }
    }
}

fn send_undelivery(
    time: Res<Time>,
    mut timer: ResMut<UTimerState>,
    mut send_events: ResMut<SendEvents>,
) {
    timer.timer.tick(time.delta_seconds);
    if timer.timer.finished {
        send_events.send(
            Delivery::new(&NetworkTypes::Message("v".to_owned()))
                .unwrap()
                .into(),
        );
        timer.timer.reset();
    }
}
