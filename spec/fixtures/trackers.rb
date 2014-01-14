def fake_trackers
  {
    "on_error"              => {
      "wfid"       => nil,
      "action"     => "error_intercepted",
      "id"         => "on_error",
      "conditions" => nil,
      "msg"        => {
        "action"    => "launch",
        "wfid"      => "replace",
        "tree"      => [ "define", {}, [["error_dispatcher",{},[]]] ],
        "workitem"  => "replace",
        "variables" => "compile"
      }
    },
    "global_tracker"        => {
      "wfid"       => nil,
      "action"     => "left_tag",
      "id"         => "global_tracker",
      "conditions" => { "tag" => [ "the_event" ] },
      "msg"        => {
        "action"   => "reply",
        "fei"      => {
          "engine_id" => "engine",
          "wfid"      => "my_wfid",
          "subid"     => "dc6cff8c33746836353224d7b3d10b4b",
          "expid"     => "0_0_0"
        },
        "workitem" => "replace",
        "flavour"  => "await"
      }
    },
    "local_tracker"         => {
      "wfid"       => "my_wfid",
      "action"     => "left_tag",
      "id"         => "local_tracker",
      "conditions" => { "tag" => [ "local_event" ] },
      "msg"        => {
        "action"   => "reply",
        "fei"      => {
          "engine_id" => "engine",
          "wfid"      => "my_wfid",
          "subid"     => "8cb9de101dbc38e3f375a277d025c170",
          "expid"     => "0_0_1"
        },
        "workitem" => "replace",
        "flavour"  => "await"
      }
    },
    "local_error_intercept" => {
      "wfid"       => "my_wfid",
      "action"     => "error_intercepted",
      "id"         => "local_error_intercept",
      "conditions" => { "message" => [ "/bad/" ] },
      "msg"        => {
        "action"   => "reply",
        "fei"      => {
          "engine_id" => "engine",
          "wfid"      => "my_wfid",
          "subid"     => "e4bb9b945b829019b9f1fcd266fb5bd8",
          "expid"     => "0_0_2"
        },
        "workitem" => "replace",
        "flavour"  => "await"
      }
    },
    "participant_tracker"   => {
      "wfid"       => "my_wfid",
      "action"     => "dispatch",
      "id"         => "participant_tracker",
      "conditions" => { "participant_name" => [ "goose", "bunnies" ] },
      "msg"        => {
        "action"   => "reply",
        "fei"      => {
          "engine_id" => "engine",
          "wfid"      => "my_wfid",
          "subid"     => "6ddfe62d9aa2a25d8928de987c24caf1",
          "expid"     => "0_0_3"
        },
        "workitem" => "replace",
        "flavour"  => "await"
      }
    }
  }
end