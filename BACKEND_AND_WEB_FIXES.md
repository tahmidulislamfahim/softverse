# Softverse — Backend & Website Fixes Guide
**Source:** Client Feedback Document (*Feedback November 1st, 2026 / October 11, 2026*)

This document covers:
1. **Backend API & Database changes required by the Mobile Apps** (`softverse` POS & `softverse-dash` Dashboard)
2. **Backend Security, Auth & Core API fixes**
3. **Business Dashboard Website fixes**
4. **Super Manager Dashboard Website fixes**

---

## Part 1: Backend Changes Required by the Mobile Apps

Because the backend uses NestJS `ValidationPipe` (which strips or rejects unknown fields), the mobile apps cannot complete the following features until the backend DTOs, database schema, and endpoints are updated.

### 1. Split Payment Support (`POST /checkout` & `POST /checkout/:id/pay`)
- **Client Request:** Allow customers to pay for a single purchase using multiple payment methods (e.g., part of the total in Cash HTG and the remaining amount via Bank Transfer or NatCash).
- **Current Limitation:** The checkout payload only accepts a single boolean map:
  ```json
  "payment": {
    "cash": true,
    "card": false,
    "due": false,
    "installment": false
  },
  "amountReceived": 1500
  ```
- **How to Fix in Backend:**
  1. Update `CreateCheckoutDto` and `PayCheckoutDto` to accept an optional `payments` array (while keeping `"payment"` backward-compatible):
     ```json
     "payments": [
       { "method": "cash", "label": "Cash", "amount": 1000 },
       { "method": "natcash", "label": "NatCash", "amount": 500 }
     ]
     ```
  2. Validate that the sum of `payments[].amount` equals or exceeds the payable total (unless one of the splits or the order status is `due`).
  3. Store the payment breakdown on the order/transaction record and return `payments` in `GET /checkout/:id`, `GET /checkout/:id/receipt`, `GET /transactions`, and `GET /transactions/:id` so receipts and transaction details can display each payment method and amount.

---

### 2. Custom Payment Methods & Cash Sub-Options (`GET /payment-types`, `POST /payment-types`, `PATCH /payment-types/:id`)
- **Client Request:**
  - Remove "Installment" from the system.
  - Allow businesses to create and customize payment method names (e.g., `Cash`, `NatCash`, `Bank Transfer`, `Mobile Cash`) or define sub-options under Cash.
- **Current Limitation:** `/payment-types` only returns the 4 fixed keys (`cash`, `card`, `due`, `installment`).
- **How to Fix in Backend:**
  1. Remove or disable `installment` from default payment types.
  2. Update the `PaymentType` entity/table so each business can create, rename, enable/disable, and delete custom payment methods (`id`, `key`, `label`, `parentMethod` e.g. `cash`, `isActive`, `storeId`).
  3. Expose CRUD endpoints (`GET /payment-types`, `POST /payment-types`, `PATCH /payment-types/:id`, `DELETE /payment-types/:id`) for both the Business Dashboard Website and the POS app.

---

### 3. Partial / Multi-Item Refunds (`POST /checkout/:id/refund`)
- **Client Request:** Allow refunding specific items and custom quantities from an invoice (e.g., if an invoice has 24 bread + 24 sugar, allow refunding up to 24 sugar and up to 24 bread in any quantity, rather than only refunding the entire invoice or one bulk item at a time).
- **Current Limitation:** `POST /checkout/:id/refund` currently takes an empty body and marks the entire order as `"refunded"`.
- **How to Fix in Backend:**
  1. Update `POST /checkout/:id/refund` to accept a partial refund payload:
     ```json
     {
       "items": [
         { "itemId": "uuid-1", "quantity": 5 },
         { "itemId": "uuid-2", "quantity": 10 }
       ],
       "reason": "Optional reason"
     }
     ```
  2. Track `refundedQuantity` per line item on the order so a cashier cannot refund more than the purchased quantity (`purchasedQty - alreadyRefundedQty`).
  3. Restock inventory only for the refunded quantities (`inStock += refundedQty` when `trackStock == true`).
  4. Proportionally adjust/return loyalty points and recalculate refunded totals.
  5. Set order status to `partially_refunded` if items remain, or `refunded` when all items/quantities are refunded.

---

### 4. Direct Item Assignment When Creating/Editing Categories (`POST /categories` & `PATCH /categories/:id`)
- **Client Request:** Allow assigning items directly when creating a category (Loyverse style).
- **Current Limitation:** `POST /categories` and `PATCH /categories/:id` only accept `name`, `color`, and `isActive`.
- **How to Fix in Backend:**
  1. Add an optional `itemIds: string[]` field to `CreateCategoryDto` and `UpdateCategoryDto`.
  2. Inside the category creation/update transaction, bulk-update all matching items belonging to the business (`UPDATE items SET category_id = :categoryId WHERE id IN (:...itemIds)`).
  3. Return the assigned `itemIds` (and updated `itemCount`) in `GET /categories/admin` and `GET /categories/:id`.

---

### 5. Simple Sequential Invoice Numbering (`POST /checkout`)
- **Client Request:** Invoice numbers are currently in a long/UUID-like format that is difficult to read; make them simple like `POS-123047` or `123047`.
- **How to Fix in Backend:**
  1. Generate a human-readable sequential `orderNumber` / `invoiceNumber` per business or per store (e.g., `POS-100001` or `123047` using an auto-incrementing sequence/counter per business).
  2. Return this short `invoiceNumber` / `orderNumber` in `POST /checkout`, `GET /transactions`, and `GET /checkout/:id`.

---

### 6. Low-Stock & Out-of-Stock Push Notifications (`softverse-dash`)
- **Client Request:** In the Mobile Dashboard app (`softverse-dash`), `Settings → Stock notifications` is activated, but no push notification arrives when a sale causes an item to become Low Stock or Out of Stock.
- **How to Fix in Backend:**
  1. Add an endpoint (`POST /auth/me/device-token` or `POST /notifications/register-device`) to store Firebase Cloud Messaging (FCM) device tokens for manager accounts.
  2. In the checkout/inventory deduction service, whenever an item with `trackStock == true` crosses `inStock <= 0` (Out of Stock) or `inStock <= lowStock` (Low Stock), check if `stock_notifications` is enabled for that business/user and send an FCM push notification to registered devices.

---

### 7. Checkout Speed Optimization (`POST /checkout` taking up to 20s)
- **Client Request:** Saving an order / making a sale takes up to 20 seconds to conclude.
- **How to Fix in Backend:**
  1. Profile `POST /checkout` and `POST /checkout/:id/pay`.
  2. Batch item lookup and stock deduction queries (`WHERE id IN (...)`) instead of running N+1 sequential queries inside a loop for each cart item.
  3. Move non-critical side effects (emailing receipts, analytics aggregation, webhook/notification dispatch) out of the request-response cycle into an async background job/event emitter so `POST /checkout` returns in `< 300ms`.

---

## Part 2: Backend Security & Business Logic Fixes

### 1. Session Invalidation on Password Change & LAN Back-Office Link Auth
- **Client Request:**
  - Copying and pasting the LAN back-office link directly into a browser automatically logs into the client's back office without asking to authenticate.
  - Even after changing the password, existing sessions remain logged in.
- **How to Fix in Backend:**
  1. **Remove any auto-login token or pre-authenticated session in the back-office URL.** Require standard JWT/cookie authentication on the back-office login route.
  2. **Invalidate sessions on password change:**
     - Add a `tokenVersion` (integer) or `passwordChangedAt` timestamp column on the `User` entity.
     - Include `tokenVersion` (or compare `iat < passwordChangedAt`) inside the JWT guard (`JwtAuthGuard`) and refresh-token verification.
     - When `resetPassword` or `changePassword` is called, increment `tokenVersion` and delete all stored refresh tokens/sessions for that user.

### 2. Employee Approval Bypass Bug
- **Client Request:** When a Business Manager adds an employee, approval is initially `pending` (which is correct), but if they cancel and re-do it, the system adds the employee immediately without Super Manager approval.
- **How to Fix in Backend:**
  1. Inspect the employee creation/re-invitation controller/service.
  2. Ensure that when a canceled/deleted/rejected employee record with the same email is re-created or re-activated, its status is explicitly forced to `PENDING_APPROVAL` (`isApproved = false`, `status = 'pending'`) rather than defaulting to `active` on an upsert/restore path.

### 3. POS Device Single-Terminal Lock (`Settings → Store → POS Device`)
- **Client Request:** More than one terminal can connect to the same POS Device name. Once a POS Device is chosen/active on a terminal, connecting to that same device from another terminal should be blocked.
- **How to Fix in Backend:**
  1. When a terminal binds to a `posDeviceId` (or sends `/terminals/heartbeat`), bind the `terminalId` and `lastSeenAt` to that `PosDevice` record.
  2. Reject binding requests (`409 Conflict`) if `posDevice.activeTerminalId != null && posDevice.activeTerminalId != requestingTerminalId` (unless the device was explicitly released via `/terminals/end` or the manager disconnected it).
  3. Clear the lock when `/terminals/end` or `/auth/logout` is called.

### 4. Per-Store Receipt Settings (`GET / PATCH /business-admin-dashboard/settings/receipt`)
- **Client Request:** Receipt settings can currently only be configured for one store (business-wide); each store should be able to have its own receipt settings.
- **How to Fix in Backend:**
  1. Add `storeId` (nullable for fallback default, or foreign key to `Store`) to the `ReceiptSettings` table with a unique constraint on `(businessId, storeId)`.
  2. Update `GET /business-admin-dashboard/settings/receipt?storeId=...` and `PATCH /business-admin-dashboard/settings/receipt?storeId=...` to read/write settings for the specified `storeId` (falling back to the business default if a store hasn't customized its receipt yet).

### 5. Super Manager vs. Business Manager Login Collision
- **Client Request:** Sometimes when logging in with Super Manager credentials, the user lands in a Business Manager dashboard and has to disconnect and reconnect to access the Super Manager dashboard.
- **How to Fix in Backend:**
  1. Check the `Users` table for duplicate accounts sharing the same email across `SUPER_ADMIN` / `SUPER_MANAGER` and `BUSINESS_ADMIN` roles, or enforce a unique email constraint across all roles.
  2. In `POST /auth/login`, ensure role resolution is deterministic and returns the exact `role` (`SUPER_MANAGER` vs `BUSINESS_MANAGER`), and clear any stale business-scoped cookies/tokens on login.

### 6. Delete Company / Business Account
- **Client Request:**
  - Business Manager should be able to delete their own company's account.
  - Super Manager must be able to delete any company's account.
- **How to Fix in Backend:**
  1. Add `DELETE /business-admin-dashboard/account` (for Business Manager, requiring password confirmation) and `DELETE /super-admin/businesses/:id` (for Super Manager).
  2. Perform a cascading soft-delete or hard-delete of the business, its stores, terminals, and active sessions, immediately revoking all tokens for that business.

---

## Part 3: Business Dashboard Website Fixes

1. **Alphabetical Item Sorting (`A → Z`)**:
   - Sort the items table/list alphabetically by `name` (`ORDER BY LOWER(name) ASC` on backend `GET /items` & `GET /inventory`, or sort on the frontend table).
2. **Allow Decimal Numbers for Price and Cost (e.g., `0.5`)**:
   - In the Create/Edit Item form on the web dashboard, change `<input type="number" step="1">` to `<input type="number" step="any" min="0">` and ensure the form validator uses `parseFloat()` instead of `parseInt()` / integer regex.
3. **Currency Symbol on Price/Cost Inputs**:
   - Replace hardcoded `$` input prefixes on the Item creation/edit page with the business's selected currency symbol from profile settings.
4. **Multiline Text Inputs for Receipt Settings & Item Description**:
   - Replace single-line `<input type="text">` fields with `<textarea rows="3">` (with `white-space: pre-wrap; word-break: break-word`) for Receipt Business Name, Receipt Header, Receipt Footer, and Item Description so long text wraps to the next line naturally.
5. **Per-Store Selector on Receipt Settings Page**:
   - Add a Store dropdown on `Settings → Receipt Setting` so the manager can configure receipt headers/footers/logos per store.
6. **Delete Company Account Button**:
   - Add a "Delete Company Account" danger zone section with confirmation modal in Business Profile / Settings.

---

## Part 4: Super Manager Dashboard Website Fixes

1. **Formal Domain Hosting (`www.softverse.com`)**:
   - Point DNS (`A` / `CNAME` records for `softverse.com` and `www.softverse.com`) to the production server, configure Nginx/Caddy reverse proxy with Let's Encrypt SSL (HTTPS), and update `BASE_URL` / CORS origins.
2. **Role Routing on Login**:
   - When `user.role === 'SUPER_MANAGER'` (or `SUPER_ADMIN`), always route to the Super Manager Dashboard and clear any cached Business Manager state in `localStorage`.
3. **Delete Company Account Action**:
   - Add a Delete action button (with confirmation dialog) on the Companies/Businesses list in the Super Manager Dashboard connected to `DELETE /super-admin/businesses/:id`.

