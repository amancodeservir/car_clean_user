# Car Clean Plus — pending points

Checked 10 Oct 2026. **Done** means the screen and API are in the apps and the local backend. **Pending** means it is not finished, or it still cannot run for a real customer.

The live API at `https://carcleanplus-backend.vercel.app/api` has not been updated, so Done items that call a new route work only after deploy.

## Summary

| Status | Count |
|---|---:|
| Done | 40 |
| Pending | 4 |
| **Total** | **44** |

| Status | No |
|---|---|
| Pending | 1, 2, 11, 39 |
| Done | 3–10, 12–38, 40–44 |

## Points

| No | Status | Type | Area | Priority | Point | Current state |
|---:|---|---|---|---|---|---|
| 1 | Pending | Issue | Backend | P1 | Deploy the new backend | Staff jobs, my-bookings, catalog, and desk routes exist on this computer. Production still returns 404 for the new paths. |
| 2 | Pending | Feature | Customer | P1 | UPI and card payment in the app | Cash, UPI at the car, and a card link are in the booking screen. A live card charge still needs Razorpay keys on the server, then a deploy. |
| 3 | Done | Feature | Customer | P1 | Alert when the washer moves | While the app is open, a status change raises a phone alert. If mail is configured, the same update is emailed so it arrives when the app is closed. |
| 4 | Done | Feature | Customer | P1 | Saved vehicles | Profile can save a vehicle name and size on the account. |
| 5 | Done | Feature | Customer | P1 | Map pin and service-area check | Booking can drop a pin. A pin outside the city zone is refused. A far pin inside the zone adds a travel fee. |
| 6 | Done | Feature | Staff | P1 | Navigate to the car | Staff open Maps from the job, using the pin or the address. |
| 7 | Done | Feature | Staff | P1 | Before and after photos | Staff can attach a camera photo to the job. |
| 8 | Done | Feature | Admin | P1 | Prices edited in the wash desk | Car and bike prices are one table the desk can save. The app reads that table. |
| 9 | Done | Bug | Admin | P1 | Festival offer does not change the app price | An active festival discount, or a festive price, is applied when the app loads the price table. |
| 10 | Done | Bug | Customer | P2 | Notification bell does nothing | The home bell opens the alerts list. |
| 11 | Pending | Issue | Customer | P1 | My orders stay on the phone until deploy | Against the new API, orders come from the server. Production still returns 404, so a new phone still falls back to the saved list until deploy. |
| 12 | Done | Issue | Customer | P2 | Old website bookings may not show in the app | My-bookings matches the account or the last 10 digits of the phone, and claims the older ticket. |
| 13 | Done | Feature | Customer | P2 | Reschedule a booking | A pending or confirmed wash can move to another date and slot while that slot is free. |
| 14 | Done | Feature | Customer | P2 | Booking receipt | The ticket can open a receipt with service, vehicle, GST, and total. |
| 15 | Done | Feature | Customer | P2 | Rate the wash | A finished wash can be scored from 1 to 5. |
| 16 | Done | Feature | Customer | P2 | Book again | The ticket can start a new booking with the same service and car or bike. |
| 17 | Done | Feature | Customer | P2 | Add-ons | Wax, interior, and engine bay can be added on the review step. |
| 18 | Done | Feature | Customer | P2 | Monthly wash plan | Profile can add the City 4 plan. A booking can use one wash from the plan. |
| 19 | Done | Feature | Customer | P2 | Promo code and referral | A code can reduce the quote. A referral adds credit on both accounts. |
| 20 | Done | Feature | Customer | P3 | Phone OTP sign-in | The phone screen sends a code to the email you enter, or by text when MSG91 is set on the server. |
| 21 | Done | Bug | Customer | P2 | OTP screen is a dead end | The screen is on the sign-in path and calls the code API. |
| 22 | Done | Feature | Staff | P2 | Mark cash collected | Staff can record cash and UPI taken at the car. |
| 23 | Done | Feature | Staff | P2 | On-shift switch | Staff can mark on shift. The assign list shows those people first. |
| 24 | Done | Feature | Staff | P3 | Clock in at the address | Staff send their location. If the job has a pin, they must be within 0.5 km. |
| 25 | Done | Feature | Admin | P2 | Create a staff login | The desk can add a washer with name, email, phone, and branch. |
| 26 | Done | Feature | Admin | P2 | Slot capacity by area | A slot stays open until that city reaches the desk capacity. The default is 4. |
| 27 | Done | Issue | Admin | P2 | One slot is company-wide | A booked slot is counted for that city, not for every city. |
| 28 | Done | Feature | Admin | P2 | Daily cash and UPI report | The desk can open a date and see cash, UPI, online, collected, and unpaid. |
| 29 | Done | Feature | Admin | P2 | Customer wash history | Opening a person shows their washes. |
| 30 | Done | Feature | Admin | P3 | WhatsApp job update | The desk opens WhatsApp with the job status filled in. |
| 31 | Done | Feature | Admin | P3 | More than one branch | The desk can add a branch name and city. |
| 32 | Done | Feature | Admin | P3 | Staff pay | Completing a job writes a payout. The desk can mark it paid. |
| 33 | Done | Improvement | Customer | P2 | Update the ticket while the screen is open | Orders refresh every 20 seconds and on pull. |
| 34 | Done | Improvement | Customer | P2 | Show the washer name and phone | The ticket shows the assigned washer and a call button. |
| 35 | Done | Improvement | Customer | P3 | Home prices and booking prices stay the same | Home, waterless, and booking read the same price table. |
| 36 | Done | Improvement | Admin | P2 | Upload a gallery photo from the phone | Gallery can attach a compressed photo, or still take a URL. |
| 37 | Done | Improvement | Admin | P3 | Filter bookings | Bookings can be filtered by status and payment, plus the text search. |
| 38 | Done | Improvement | Staff | P2 | Show tomorrow as well as today | Staff can switch the list between today and tomorrow. |
| 39 | Pending | Issue | All | P2 | No full run on a phone yet | The customer app opens on the iPhone 17 simulator. Book, assign, accept, and the alert were run against the local API. Login taps on the simulator did not finish. |
| 40 | Done | Feature | Customer | P3 | Support on a booking | The customer can message the desk about that wash. |
| 41 | Done | Feature | Admin | P3 | Refund or part payment | The desk can record a refund. A gateway refund runs when a payment id and keys exist. Staff can split cash and UPI. |
| 42 | Done | Improvement | Backend | P2 | Keep payment secrets out of source | The server reads payment keys from the environment only. Missing keys return an error instead of a built-in key. |
| 43 | Done | Feature | Customer | P3 | Travel fee outside the zone | A pin past the free radius adds the travel fee. A pin past the zone is refused. |
| 44 | Done | Improvement | Customer | P3 | Bike and car prices in one desk table | Bike rows sit in the same price table as car rows. |
