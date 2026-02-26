# ✈️ COMPLETE DOMAIN MODEL  
## (Entities — PK and FK only — underscore standard)

---

# 1️⃣ IDENTITY MODULE

### person
- id (pk)
- type_person_id (fk)

### document_identity
- id (pk)
- person_id (fk)
- type_document_id (fk)

### contact_information
- id (pk)
- person_id (fk)

### type_document
- id (pk)

### type_person
- id (pk)

---

# 2️⃣ SECURITY MODULE

### user_account
- id (pk)
- person_id (fk)
- status_user_id (fk)

### role
- id (pk)

### permission
- id (pk)

### user_role
- id (pk)
- user_account_id (fk)
- role_id (fk)

### role_permission
- id (pk)
- role_id (fk)
- permission_id (fk)

### status_user
- id (pk)

---

# 3️⃣ CUSTOMER MODULE

### customer
- id (pk)
- person_id (fk)
- type_customer_category_id (fk)

### loyalty_program
- id (pk)
- airline_id (fk)

### loyalty_account
- id (pk)
- customer_id (fk)
- loyalty_program_id (fk)

### miles_transaction
- id (pk)
- loyalty_account_id (fk)

### customer_benefit
- id (pk)
- customer_id (fk)
- type_benefit_id (fk)

### type_customer_category
- id (pk)

### type_benefit
- id (pk)

---

# 4️⃣ AIRCRAFT MANAGEMENT MODULE

### aircraft
- id (pk)
- aircraft_model_id (fk)
- status_aircraft_id (fk)

### aircraft_model
- id (pk)
- type_aircraft_id (fk)

### cabin_configuration
- id (pk)
- aircraft_id (fk)

### seat
- id (pk)
- cabin_configuration_id (fk)
- type_seat_id (fk)
- fare_class_id (fk)

### maintenance_history
- id (pk)
- aircraft_id (fk)
- maintenance_provider_id (fk)
- type_maintenance_id (fk)

### maintenance_provider
- id (pk)
- person_id (fk)

### status_aircraft
- id (pk)

### type_aircraft
- id (pk)

### type_seat
- id (pk)

### type_maintenance
- id (pk)

---

# 5️⃣ AIRPORT MANAGEMENT MODULE

### airport
- id (pk)
- geolocation_id (fk)

### terminal
- id (pk)
- airport_id (fk)

### boarding_gate
- id (pk)
- terminal_id (fk)

### runway
- id (pk)
- airport_id (fk)

### airport_regulation
- id (pk)
- airport_id (fk)

---

# 6️⃣ FLIGHT CONTROL MODULE

### flight
- id (pk)
- aircraft_id (fk)
- origin_airport_id (fk)
- destination_airport_id (fk)
- status_flight_id (fk)

### flight_segment
- id (pk)
- flight_id (fk)
- origin_airport_id (fk)
- destination_airport_id (fk)

### flight_delay_reason
- id (pk)
- flight_id (fk)
- type_delay_reason_id (fk)

### status_flight
- id (pk)

### type_delay_reason
- id (pk)

---

# 7️⃣ BOARDING MODULE

### check_in
- id (pk)
- ticket_id (fk)

### boarding_pass
- id (pk)
- ticket_id (fk)
- flight_segment_id (fk)
- boarding_group_id (fk)

### boarding_group
- id (pk)

### boarding_validation
- id (pk)
- boarding_pass_id (fk)
- boarding_gate_id (fk)

---

# 8️⃣ SALES MODULE

### sale
- id (pk)
- person_customer_id (fk)
- status_sale_id (fk)

### reservation
- id (pk)
- sale_id (fk)
- status_reservation_id (fk)

### ticket
- id (pk)
- sale_id (fk)
- person_passenger_id (fk)
- flight_segment_id (fk)
- status_ticket_id (fk)

### fare
- id (pk)

### fare_class
- id (pk)

### seat_assignment
- id (pk)
- ticket_id (fk)
- seat_id (fk)

### baggage
- id (pk)
- ticket_id (fk)
- type_baggage_id (fk)

### status_sale
- id (pk)

### status_reservation
- id (pk)

### status_ticket
- id (pk)

### type_baggage
- id (pk)

---

# 9️⃣ PAYMENT MODULE

### payment
- id (pk)
- sale_id (fk)
- type_payment_method_id (fk)
- status_payment_id (fk)

### payment_transaction
- id (pk)
- payment_id (fk)

### refund
- id (pk)
- payment_id (fk)

### status_payment
- id (pk)

### type_payment_method
- id (pk)

---

# 🔟 BILLING MODULE

### invoice
- id (pk)
- sale_id (fk)
- currency_id (fk)

### invoice_detail
- id (pk)
- invoice_id (fk)

### tax
- id (pk)

### exchange_rate
- id (pk)
- source_currency_id (fk)
- target_currency_id (fk)

### currency
- id (pk)

---

# 1️⃣1️⃣ GEOLOCATION MODULE

### continent
- id (pk)

### country
- id (pk)
- continent_id (fk)

### state
- id (pk)
- country_id (fk)

### city
- id (pk)
- state_id (fk)

### district
- id (pk)
- city_id (fk)

### address
- id (pk)
- district_id (fk)

### coordinate
- id (pk)
- address_id (fk)

### time_zone
- id (pk)

### geolocation
- id (pk)
- country_id (fk)
- state_id (fk)
- city_id (fk)
- district_id (fk)
- address_id (fk)
- coordinate_id (fk)
- time_zone_id (fk)

---

# 1️⃣2️⃣ AIRLINE

### airline
- id (pk)