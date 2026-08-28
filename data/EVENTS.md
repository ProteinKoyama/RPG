# JSONイベントの編集方法

イベントと会話は `res://data/events.json` で管理します。NPCまたは
`GenericEventArea` のInspectorでは、実行したいイベントのキーを `Event Id` に指定します。

## 会話とフラグの例

```json
"sample_event": {
  "events": [
    {
      "type": "dialog",
      "lines": [
        {"speaker": "村人", "message": "こんにちは。"},
        {"speaker": "主人公", "message": "こんにちは！"}
      ]
    },
    {"type": "set_flag", "flag_key": "sample_talk_done", "value": true}
  ]
}
```

`events` は上から順番に実行されます。

## 対応イベント

- `dialog`: `lines` に `speaker` と `message` を記述
- `talk`: 既存の `dialogs.json` を `dialog_id` で呼び出す
- `set_flag`: `flag_key`, `value`
- `flag_branch`: `flag_key`, `when_true`, `when_false` に別のイベントIDを指定
- `battle`: `enemy_ids`, `bgm_path`, `escape_enabled`, `on_win`, `on_lose`, `on_escape`
- `give_item`: `item_id`, `amount`, `show_dialog`
- `join`: `member_id`, `show_dialog`
- `learn_skill`: `member_id`, `skill_id`, `show_dialog`
- `change_map`: `scene_path`, `spawn_point`
- `bgm`: `bgm_path`
- `node_animation`: `target_node_path`, `animation_name`
- `cutscene`: `event_key`

分岐先や戦闘結果にはイベント配列を直接ネストせず、別のイベントIDを指定します。

```json
"npc_talk": {
  "events": [
    {
      "type": "flag_branch",
      "flag_key": "npc_talk_done",
      "when_true": "npc_repeat_talk",
      "when_false": "npc_first_talk"
    }
  ]
}
```
