# Invoice check / public invoices filter by
#   EXTRACT(month FROM invoice_date) = ? [AND EXTRACT(year FROM invoice_date) = ?]
# which can't use a plain column index, so every load scanned the whole table.
# Month first so the month-only filter (public invoices) can use it too.
# Built CONCURRENTLY so they don't lock writes in production.
class AddInvoiceMonthExpressionIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :invoices,
              "(EXTRACT(month FROM invoice_date)), (EXTRACT(year FROM invoice_date))",
              name: 'idx_invoices_invoice_month_year',
              algorithm: :concurrently, if_not_exists: true
    add_index :booking_invoices,
              "(EXTRACT(month FROM invoice_date)), (EXTRACT(year FROM invoice_date))",
              name: 'idx_booking_invoices_invoice_month_year',
              algorithm: :concurrently, if_not_exists: true
    # Range filters on invoice_date (e.g. previous-balance lookups `invoice_date < ?`).
    add_index :invoices, :invoice_date,
              algorithm: :concurrently, if_not_exists: true
  end
end
