# NextMeet widgets

14 widget designs, each with its states. Sizes are Android home screen cells. Designs are drawn at 174 px (small), 358 x 84 (wide), 358 x 174 (medium) and 358 x 358 (large); build them as responsive layouts. PNG files are transparent and exported at 3x.

| Widget | Size | Data needed | Refresh | Tap action | States |
|---|---|---|---|---|---|
| Distance & Battery | Medium (4x2) | distance in km (from both cities), partner battery %, partner local time and timezone, online status | every 15 min, or on push | Open Home | normal, low battery (under 20%), probably asleep (23:00 to 07:00 their time) |
| Live Heartbeat Sync | Small (2x2) | partner_touching flag, bpm, last beat time | push when the partner touches their phone | Open Heartbeat sync | partner touching, idle, partner offline |
| Reunion Countdown | Medium (4x2) | next meetup date and time, optional route (airport codes) | hourly, and at midnight | Open Plan, Trips | days and hours, tomorrow, today |
| Daily Moments Photo | Large (4x4) | partner's latest moment image, caption, time, your own latest moment thumbnail | push when a moment arrives | Open Moment viewer; heart button sends a reaction | partner moment, waiting for partner, your moment sent |
| Together Counter | Small (2x2) | together since date | daily | Open Milestones | single state |
| Quick Touch | Small (2x2) | none (sends an action) | none | Each button sends a touch without opening the app (miss you, hug, touch, cheer) | single state, brief sent confirmation |
| Two Clocks | Wide (4x1) | both timezones, distance | every minute | Open Home | single state |
| Next Milestone | Small (2x2) | next milestone date, days left | daily | Open Milestones | single state, today |
| Game Status | Small (2x2) | active game, whose turn | push | Open the game | your move, partner's turn |
| Love Note | Medium (4x2) | latest letter, whisper or note preview, sender, time | push | Open Read letter | normal, sealed letter (show a lock) |
| Trip Tracker | Medium (4x2) | flight or train status, progress, times | every 5 min while travelling | Open Flight tracker | scheduled, in the air, landed |
| Next Event | Medium (4x2) | next two shared events | every 30 min | Open Calendar | normal, nothing planned |
| Memory of the Day | Large (4x4) | a memory from this date in a past year | daily | Open Memory detail | memory, none today |
| Couple Dashboard | Large (4x4) | partner status, both times, distance, countdown, together time, streak | every 15 min | Heart button sends a heartbeat; quick buttons send touches | normal |

## Colour options
Pink (default), violet, butter, mint and ink. The Reunion Countdown shows all five in `png/colours`; apply the same swap to any widget (background, text, accent, track).

## Notes
- The four widgets in your current app (Distance & Battery, Live Heartbeat Sync, Reunion Countdown, Daily Moments Photo) keep their names and sizes. The other ten are new proposals.
- Corner radius 28 to 36, solid backgrounds, no shadows, Nunito 600 and 800.
- Sample data in the images: Anna and Rahul, 8,420 km, 23 days 14 hours, 992 days together.
- Light colours only in this pack. Dark mode versions can be made on request.
