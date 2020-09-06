use bevy::prelude::*;
use common::{
    Delivery, NetworkConnectionInfo, NetworkEvent, NetworkEvents, NetworkPlugin, NetworkTypes,
    SendEvents,
};

fn deser(del: Delivery) -> NetworkTypes {
    common::deserialize(&del.data().unwrap()).unwrap()
}

fn main() {
    App::build()
        .init_resource::<TimerState>()
        .add_plugin(bevy::type_registry::TypeRegistryPlugin)
        .add_plugin(bevy::core::CorePlugin)
        .add_plugin(bevy::transform::TransformPlugin)
        .add_plugin(bevy::diagnostic::DiagnosticsPlugin)
        .add_plugin(bevy::asset::AssetPlugin)
        .add_plugin(bevy::scene::ScenePlugin)
        .add_plugin(bevy::app::ScheduleRunnerPlugin::default())
        .add_plugin(NetworkPlugin)
        .add_startup_system(setup.system())
        .add_system(send_delivery.system())
        .add_system(print_network_events.system())
        .run();
}

fn setup(mut con_info: ResMut<NetworkConnectionInfo>) {
    con_info.server("127.0.0.1:5555").unwrap();
}

struct TimerState {
    timer: Timer,
}

impl Default for TimerState {
    fn default() -> Self {
        Self {
            timer: Timer::from_seconds(2.0, true),
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
            Delivery::new(&NetworkTypes::Message("test".to_owned()))
                .unwrap()
                .reliable()
                .into(),
        );
        timer.timer.reset();
    }
}

fn print_network_events(mut netevents: ResMut<NetworkEvents>) {
    for ev in netevents.drain() {
        match ev {
            NetworkEvent::Received(del) => println!("{:?}", deser(del)),
            _ => println!("{:?}", ev),
        }
    }
}