# Softverse — Mobile Apps Fixes Guide (`softverse` & `softverse-dash`)
**Source:** Client Feedback Document (*Feedback November 1st, 2026 / October 11, 2026*)

This document tracks all mobile app items across:
- **`softverse`** (Main POS Mobile App — `f:\Office\softverse`)
- **`softverse-dash`** (Mobile Dashboard App — `F:\Office\softverse-dash`)

---

## Section A: Previously Confirmed & Completed Items

1. **[DONE] Static "Combo Pack 1" (`Mouse + Keyboard`, `2 pcs Keyboard`, `2 pcs Mouse`) in Inventory Item Details**
   - **Status:** [DONE] Fixed in `softverse` (`lib/features/inventory/controller/item_detail_controller.dart`, `inventory_product.dart`, `modifier_group.dart`, `modifier_section.dart`, `item_detail_screen.dart`).
   - **What was done:** Removed all hardcoded static modifier and expiration data and connected `ItemDetailController` to `GET /items/:id` (`ApiConstants.item(id)`).
2. **[DONE] Loyalty Program in Customer Profile & Checkout**
   - **Status:** [DONE] Implemented in commit `5c32a57` (`view_customer_screen.dart`, `loyalty_points_tile.dart`, `checkout_controller.dart`). Managers can view/edit points in Customer Profile and cashiers can redeem points as a discount at checkout.
3. **[DONE] Generate Payment Invoice/Receipt When Collecting a Due Balance**
   - **Status:** [DONE] Implemented in commit `b68600e` (`payment_receipt.dart`, `customer_due_orders_controller.dart`, `invoice_controller.dart`).

---

## Section B: `softverse` (Main POS App) — Frontend Fixes

### 1. [DONE] Hardcoded `$` Sign When Adding Price or Cost
- **Status:** [DONE]
- **Files Modified:** `lib/features/item/views/screens/create_item_screen.dart`, `lib/features/item/controller/create_item_controller.dart`.
- **Implementation:**
  - Replaced hardcoded `hintText: '\$0.00'` with dynamic currency formatting `hintText: AppHelperFunctions.formatCurrency(0)`.
  - Enabled decimal keypad support (`TextInputType.numberWithOptions(decimal: true)`).
  - Sanitized `CreateItemController._number()` to strip non-numeric currency prefixes and symbols automatically.

### 2. [DONE] Prevent Bypassing Store Selection with Back Button After Login
- **Status:** [DONE]
- **Files Modified:** `lib/features/store/views/screens/store_select_screen.dart`.
- **Implementation:**
  - Wrapped screen in `PopScope(canPop: !mustPick)` so cashiers cannot bypass store selection via hardware/gesture back when no store is selected.
  - Hid AppBar leading back button when `currentStoreId == null`.

### 3. [DONE] "Unauthorized" Notification When Logging Out
- **Status:** [DONE]
- **Files Modified:** `lib/core/services/session_lifecycle_service.dart`, `lib/features/auth/controller/auth_controller.dart`, `lib/core/utils/helpers/app_helper.dart`.
- **Implementation:**
  - Added `isSigningOut` / `suppressAuthErrors` flag during the logout lifecycle.
  - Prevented late 401 network responses from firing false-positive "Unauthorized" snackbars during or right after session signout.

### 4. [DONE] Alphabetical Sorting of Items (`A → Z`)
- **Status:** [DONE]
- **Files Modified:** `lib/features/home/controller/home_controller.dart`, `lib/features/inventory/controller/inventory_controller.dart`.
- **Implementation:**
  - Added alphabetical sorting by product name (`.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))`) across catalog sales lists and inventory lists.

### 5. [DONE] Move "Items" Menu from "More" into "Inventory"
- **Status:** [DONE]
- **Files Modified:** `lib/features/more/views/screens/more_screen.dart`, `lib/features/inventory/views/screens/inventory_screen.dart`.
- **Implementation:**
  - Removed the `Item` tile from `MoreScreen`.
  - Added an `Items` management action button in `InventoryScreen` AppBar actions linking directly to `AppRoute.getItemsMenuScreen()`.

### 6. [DONE] Move "Customer" Icon to Top of Sales Screen & Remove from "More"
- **Status:** [DONE]
- **Files Modified:** `lib/features/home/views/screens/home_screen.dart`, `lib/features/more/views/screens/more_screen.dart`.
- **Implementation:**
  - Added a dedicated Customers icon button in the top AppBar actions of `HomeScreen` (`AppRoute.getViewCustomerScreen()`).
  - Removed the `Customer` tile from `MoreScreen`.

### 7. [DONE] PIN Lock Bugs (Not Asking on Reopen & Rejecting Good PIN After Wrong PIN)
- **Status:** [DONE]
- **Files Modified:** `lib/features/app_lock/controller/app_lock_controller.dart`, `lib/features/splash/controller/splash_controller.dart`.
- **Implementation:**
  - Updated `didChangeAppLifecycleState` to trigger `lock()` immediately on `paused`, `detached`, or `hidden` states instead of requiring a 15-second grace period.
  - Added automatic lock trigger on app cold-start launch in `SplashController`.
  - Implemented instant local cached PIN hash verification (`< 10ms`) in `unlock()` so cashiers do not wait on network roundtrips.
  - Immediately cleared error messages when entering new digits.

### 8. [DONE] Printer Disconnecting After App Closes
- **Status:** [DONE]
- **Files Modified:** `lib/core/bindings/controller_binder.dart`, `lib/features/printer/controller/printer_controller.dart`.
- **Implementation:**
  - Registered `PrinterController` as `permanent: true` in `ControllerBinder` so it is initialized at app startup.
  - Added `autoConnectSavedPrinter()` called in `PrinterController.onInit()` to automatically reconnect to the default physical/Bluetooth printer on app launch.

### 9. [DONE] Sales & Checkout Interface Redesign (Loyverse-Style UX)
- **Status:** [DONE]
- **Files Modified:**
  - `lib/features/home/views/screens/home_screen.dart`
  - `lib/features/checkout/views/screens/checkout_screen.dart`
  - `lib/features/checkout/widgets/modifier_discount_toggle.dart`
  - `lib/core/common/widgets/quantity_stepper.dart`
  - `lib/features/checkout/widgets/cart_item_card.dart`
  - `lib/features/checkout/controller/checkout_controller.dart`
- **Implementation:**
  1. **Top Cart / Ticket Review:** Replaced `TillIdentityTitle` in the sales AppBar with a Ticket Review indicator displaying shopping cart icon, live item badge count, and running ticket total (`Ticket ($total)`) that navigates directly to checkout on tap.
  2. **Direct Numeric Quantity Entry:** Made the quantity text in `QuantityStepper` tappable to open an input dialog so cashiers can type any quantity directly instead of tapping `(+)` repeatedly.
  3. **Modifier & Discount Buttons:** Redesigned `ModifierDiscountToggle` into prominent, large (height 48h) segmented buttons with icons (`Iconsax.edit_2`, `Iconsax.percentage_circle`), clear active gradients, and large touch targets.
  4. **Top 3-Dot Action Menu:** Moved secondary actions (*Print Estimate / Receipt, Pending Orders, Save Order, Send to Table, Clear Order, Close Checkout*) into a top-right `PopupMenuButton` in `CheckoutScreen`.
  5. **Dedicated "Charge" Button:** Replaced cluttered inline secondary button blocks with a prominent, full-width **"Charge [Total]"** button.

### 10. [DONE] Receipt Layout & Alignment (Printed & PDF)
- **Status:** [DONE]
- **Files Modified:** `lib/features/printer/controller/printer_controller.dart`, `lib/core/utils/helpers/invoice_pdf_exporter.dart`.
- **Implementation:**
  - Reorganized printed and PDF receipt sections:
    1. Centered logo
    2. Centered business name and header note
    3. Branch, cashier, order, customer, payment details
    4. Item table (`Qty x Item`, unit price, line total)
    5. Subtotal, discounts, taxes, totals, amount received, change
    6. Centered footer note
    7. **Date & time and unique receipt ID at the very bottom below the footer**.

### 11. [DONE] Transactions & Invoice Screen Improvements
- **Status:** [DONE]
- **Files Modified:**
  - `lib/features/invoice/views/screens/invoice_screen.dart`
  - `lib/features/invoice/controller/invoice_controller.dart`
  - `lib/features/invoice/widgets/invoice_item_card.dart`
- **Implementation:**
  - Simplified invoice title in `InvoiceScreen` AppBar to avoid truncation (`Invoice : P...`).
  - Added prominent **Refund** button in top-right AppBar header.
  - Moved Print, Email / Share, Download PDF, Collect Due, and Mark Empty into a top-right 3-dot `PopupMenuButton`.
  - Added order date and time display under the Purchase Item header.
  - Updated `InvoiceItemCard` to display item quantity x unit price and line subtotal.
  - Removed redundant bottom buttons (*Print receipt, View PDF, Return home*).

### 12. [DONE] Item Description Not Working Properly
- **Status:** [DONE]
- **Files Modified:** `lib/features/item/widgets/create_item_field.dart`, `lib/features/item/views/screens/create_item_screen.dart`, `lib/features/inventory/models/inventory_product.dart`, `lib/features/inventory/views/screens/item_detail_screen.dart`.
- **Implementation:**
  - Supported multiline text (`maxLines: 3`) on the item description field.
  - Added `description` parsing to `InventoryProduct.fromApi` and rendered it in `ItemDetailScreen`.

### 13. [DONE] Checkout Speed Optimization (Frontend Part)
- **Status:** [DONE]
- **Files Modified:** `lib/features/checkout/controller/checkout_controller.dart`.
- **Implementation:**
  - Wrapped all post-checkout tasks (`fetchOrders`, `fetchTables`, `fetchTransactions`, `_sendToKdsIfEnabled`, `_printKitchenTicketsIfEnabled`) inside `unawaited(...)` so the cashier immediately sees the completed invoice without waiting on network sockets, printer spoolers, or background data sync.

---

## Section C: `softverse-dash` (Mobile Dashboard App) — Frontend Fixes

### 1. [DONE] Change Dashboard App Theme Color for Easy Identification
- **Status:** [DONE]
- **Files Modified:**
  - `lib/core/utils/constants/colors.dart`
  - `lib/core/utils/theme/widget_themes/elevated_button_theme.dart`
  - `lib/core/utils/theme/theme.dart`
- **Implementation:**
  - Updated theme to a deep teal/emerald palette (`AppColors.primary = Color(0xFF0F766E)`, gradients `0xFF0F766E` to `0xFF115E59`) to clearly distinguish Dashboard from POS.

### 2. [DONE] Alphabetical Item Sorting (`A → Z`)
- **Status:** [DONE]
- **Files Modified:** `lib/features/dashboard/controller/dashboard_controller.dart`.
- **Implementation:**
  - Added `sortInventoryByName()` sorting all inventory items alphabetically `A → Z`.

### 3. [DONE] Verify Transaction Date / Timezone Sync Between POS and Mobile Dashboard
- **Status:** [DONE]
- **Files Modified:** `lib/core/utils/helpers/app_helper.dart`.
- **Implementation:**
  - Formatted all dates and timestamps using `date.toLocal()` so dates bucket into the terminal's local day.

---

## Section D: Mobile App Features Connected to Updated Backend Endpoints

### 1. [DONE] Split Payment UI at Checkout (`softverse`)
- **Status:** [DONE]
- **Files Modified:** `lib/features/checkout/models/payment_method.dart`, `lib/features/checkout/controller/checkout_controller.dart`, `lib/features/checkout/views/screens/checkout_screen.dart`.
- **Implementation:** Added "Split Payment" bottom sheet on Checkout allowing cashiers to split an order across multiple active payment methods, auto-balance amounts, verify remaining balance, and submit `payments: [{ method, label, subMethod, amount }]` to `POST /checkout` and `POST /checkout/:id/pay`.

### 2. [DONE] Custom Payment Methods, Sub-Options & Installment Removal (`softverse`)
- **Status:** [DONE]
- **Files Modified:** `lib/features/checkout/models/payment_method.dart`, `lib/features/checkout/controller/checkout_controller.dart`.
- **Implementation:** Removed `installment` from default and visible payment options; updated `fetchPaymentTypes()` to pass `storeId` and dynamically render custom payment types and `subMethods` (e.g., NatCash, Bank Transfer) returned by `GET /payment-types`.

### 3. [DONE] Partial / Multi-Item Refund UI (`softverse`)
- **Status:** [DONE]
- **Files Modified:** `lib/features/invoice/controller/invoice_controller.dart`, `lib/features/invoice/views/screens/refund_screen.dart`, `lib/features/invoice/views/screens/refund_invoice_screen.dart`, `lib/features/invoice/widgets/invoice_item_card.dart`.
- **Implementation:** Replaced single-item radio selection with multi-item checkboxes, Select All / Clear All toggle, per-item quantity steppers (with direct numeric input up to remaining refundable quantity), optional refund reason, and `POST /checkout/:id/refund` payload `{ items: [{ lineIndex, itemId, quantity }], reason }`.

### 4. [DONE] Direct Item Assignment When Creating/Editing Categories (`softverse`)
- **Status:** [DONE]
- **Files Modified:** `lib/features/item/models/category_model.dart`, `lib/features/item/controller/category_controller.dart`, `lib/features/item/views/screens/category_form_screen.dart`.
- **Implementation:** Added searchable multi-select "Assign Items" picker in `CategoryFormScreen` that pre-selects existing category items when editing and sends `itemIds: string[]` to `POST /categories` and `PATCH /categories/:id`.

### 5. [DONE] Low Stock / Out-of-Stock Notification Preferences & Device Registration (`softverse-dash`)
- **Status:** [DONE]
- **Files Modified:** `lib/core/utils/constants/api_constants.dart`, `lib/core/services/storage_service.dart`, `lib/features/dashboard/data/dashboard_repository.dart`, `lib/features/dashboard/controller/dashboard_controller.dart`.
- **Implementation:** Connected `Settings → Stock notifications` toggle to `GET/PATCH /notifications/preferences` and `POST /notifications/register-device` with persisted local preference and device ID.

### 6. [DONE] Disappearing Items / Category Filtering & Pagination Fix (`softverse` & `softverse-dash`)
- **Status:** [DONE]
- **Files Modified:** `softverse/lib/features/home/data/home_repository.dart`, `softverse/lib/features/inventory/data/inventory_repository.dart`, `softverse/lib/features/home/models/product.dart`, `softverse/lib/features/inventory/models/inventory_product.dart`, `softverse/lib/features/home/controller/home_controller.dart`, `softverse/lib/features/inventory/controller/inventory_controller.dart`, `softverse-dash/lib/features/dashboard/data/dashboard_repository.dart`.
- **Implementation:** Increased `GET /inventory` fetch `limit=1000` so catalogs are not truncated at 50 items, and updated POS & Inventory category filtering to match by `categoryId` as well as trimmed case-insensitive `categoryName`.

### 7. [DONE - FRONTEND] Checkout Speed Optimization
- **Status:**
  - **Frontend:** [DONE] Post-checkout tasks run asynchronously (`unawaited`) so the UI unlocks immediately.
  - **Backend:** Handled by backend developer.
