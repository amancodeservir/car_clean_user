# Admin and staff app — pending work

The customer app (`car_clean_user`) is the doorstep booking app. The next project is a **separate Flutter app** for admin and staff. It uses the same API (`https://carcleanplus-backend.vercel.app/api`). Login only. No public signup. Customers stay in this app. Admin and superadmin who sign in here are asked to use the staff app.

The admin app now lives at `/Users/rajesh/Documents/car_clean_admin` (`Car Clean Admin`). It signs in with the same API, keeps customers out, and includes dashboard, bookings (status, phone booking, block slot, delete), users and roles, enquiries, gallery, and the festival offer. Staff job screens are still waiting on the backend work below.

## 1. What the admin app does

- Separate Flutter project at `/Users/rajesh/Documents/car_clean_admin`, not a screen inside the customer app.
- Email and password login against `POST /api/auth/login`.
- Session check with `GET /api/auth/me`.
- A `customer` account is refused and sent to the customer app.
- `admin` and `superadmin` open the admin shell.
- Any other role, including a future `staff` role, sees a waiting screen until staff jobs exist on the server.
- Today the backend roles are only `customer`, `admin`, and `superadmin`. There is no `staff` role yet.

## 2. Backend work

This is written in `carcleanplus_existing/backend`. It is live only after that API is deployed to Vercel. Until then the apps still talk to the current production API.

- `staff` is a role. Public register still forces `customer`. Only a superadmin can set staff.
- A booking can store the customer user and an assigned staff member.
- `GET /api/booking/mine` and `PUT /api/booking/:id/cancel` are for the signed-in customer. Cancel works while the booking is pending.
- `PUT /api/admin/bookings/:id/assign` gives a job to a staff account.
- `GET /api/staff/jobs` and `PUT /api/staff/jobs/:id/status` are the field flow: accepted, on the way, in progress, completed.

## 3. Admin screens (built in Car Clean Admin)

These screens are in the admin app and call the live API with a Bearer token. Admin middleware allows `admin` and `superadmin`. Role changes are superadmin only.

| Screen | What it does | API |
| --- | --- | --- |
| Dashboard | Counts, revenue, recent bookings | `GET /api/admin/dashboard` |
| Bookings | List, search, open one | `GET /api/admin/bookings`, `GET /api/admin/bookings/:id` |
| Booking status | Move a job through lead, pending, confirmed, completed, cancelled, blocked | `PUT /api/admin/bookings/:id/status` |
| Phone booking | Create a booking taken on the phone | `POST /api/admin/bookings/manual` |
| Block a slot | Close one slot or the whole day so the website and customer app cannot take it | same manual route, block type |
| Delete booking | Remove a bad record | `DELETE /api/admin/bookings/:id` |
| Users | List people and open one | `GET /api/admin/users`, `GET /api/admin/users/:id` |
| Roles | Superadmin sets `customer`, `admin`, or `superadmin`. An admin must not promote anyone or edit another admin | `PUT /api/admin/users/:id/role` |
| Contacts | Read website enquiries | `GET /api/admin/contacts` |
| Gallery | Add, edit, hide, delete photos | `/api/gallery` admin routes |
| Festival offer | Turn the festive price on or off | `GET /api/festival`, `PUT /api/festival` |

Time slots the customer app and website share:

- Slot 1 – 08:30 AM
- Slot 2 – 10:00 AM
- Slot 3 – 11:30 AM
- Slot 4 – 01:30 PM
- Slot 5 – 03:00 PM
- Slot 6 – 04:30 PM

Sundays are not offered in the customer app.

## 4. Staff screens

Built in the wash desk app. A staff login opens today’s assigned jobs, can call the customer, and moves the job with Accept, On the way, Start, and Complete. Those buttons work after the backend in section 2 is deployed.

## 5. Out of scope for the first admin/staff build

- Razorpay keys or payment capture inside the staff app. The website already has `POST /api/payment/create-order` and `POST /api/payment/verify-payment`. The customer app books as cash on service.
- Rebuilding the customer app.
- Push notifications and live maps. Add those after staff status updates exist, then the customer app can show them.

## 6. Suggested build order

1. Backend: `staff` role, booking owner, assignment, staff job routes, customer “my bookings”.
2. New Flutter app: login, reject customers, admin dashboard, booking list and status.
3. Manual phone booking and slot blocking.
4. Users and roles (superadmin), contacts, gallery, festival toggle.
5. Staff job list and status buttons.
6. Point the customer app at “my bookings” so orders are not only stored on the phone.
