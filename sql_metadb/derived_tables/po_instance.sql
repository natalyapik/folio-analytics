--metadb:table po_instance

-- Create a local_core table for purchase order line instance. Every po line may have location ID or holding ID or both can be 'null', if both are 'null'
--then 'no source' is present in pol_location_source.
--if holding was deleted after pol was created then there is 'deleted_holding' in pol_location_name 
--Pol_location depends on how the po is created.

DROP TABLE IF EXISTS po_instance;

CREATE TABLE po_instance AS
SELECT DISTINCT 
    pot.manual_po AS manual_po,
    poltt.rush::boolean AS rush,
    poltt.requester AS requester,
    poltt.selector AS selector,
    pot.po_number AS po_number,
    pot.id AS po_number_id,
    poltt.po_line_number AS po_line_number,
    poltt.id AS po_line_id,
    ot.code AS vendor_code, 
    ut.username AS created_by_username,
    pot.workflow_status AS po_workflow_status,
    pot.approved::boolean AS status_approved,
    jsonb_extract_path_text(po.jsonb, 'metadata', 'createdDate')::timestamptz AS created_date,  
    jsonb_extract_path_text(cdt.value::jsonb, 'name') AS bill_to,
    jsonb_extract_path_text(cdt2.value::jsonb, 'name') AS ship_to,
    poltt.instance_id AS pol_instance_id,
    it.hrid AS pol_instance_hrid,
    jsonb_extract_path_text(locations.jsonb, 'holdingId')::uuid AS pol_holding_id,
    jsonb_extract_path_text(locations.jsonb,'locationId')::uuid AS pol_location_id,     
    COALESCE (lot.name, lot2.name,'deleted_holding') AS pol_location_name,
    CASE 
        WHEN lot.name IS NULL AND lot2.name IS NULL 
        THEN 'no sourse'
        WHEN lot.name IS NULL AND lot2.name IS NOT NULL 
        THEN 'pol_holding'
        WHEN lot.name IS NOT NULL AND lot2.name IS NULL 
        THEN 'pol_location'
        ELSE 'x' END AS pol_location_source,    
    it.title AS title,
    poltt.publication_date AS publication_date,
    poltt.publisher AS publisher
    FROM folio_orders.po_line as pol
    CROSS JOIN LATERAL jsonb_array_elements((pol.jsonb #> '{locations}')::jsonb) AS locations (data)
    LEFT JOIN folio_orders.po_line__t AS poltt ON pol.id = poltt.id
    LEFT JOIN folio_inventory.instance__t AS it ON poltt.instance_id = it.id
    LEFT JOIN folio_inventory.location__t AS lot ON (locations.jsonb #>> '{locationId}')::uuid = lot.id
    LEFT JOIN folio_orders.purchase_order__t pot ON pol.purchaseorderid = pot.id 
    LEFT JOIN folio_inventory.holdings_record__t AS ih ON jsonb_extract_path_text(locations.jsonb, 'holdingId')::uuid = ih.id
    LEFT JOIN folio_inventory.location__t AS lot2 ON ih.permanent_location_id = lot2.id 
    LEFT JOIN folio_organizations.organizations__t AS ot ON pot.vendor = ot.id
    LEFT JOIN folio_orders.purchase_order AS po ON pot.id = po.id
    LEFT JOIN folio_configuration.config_data__t as cdt ON jsonb_extract_path_text(po.jsonb, 'billTo')::uuid = cdt.id
    LEFT JOIN folio_configuration.config_data__t AS cdt2 ON jsonb_extract_path_text(po.jsonb, 'shipTo')::uuid = cdt2.id
    LEFT JOIN folio_users.users__t AS ut ON jsonb_extract_path_text(po.jsonb, 'metadata', 'createdByUserId')::uuid = ut.id;

COMMENT ON COLUMN po_instance.manual_po IS 'If true, order cannot be sent automatically, e.g. via EDI';

COMMENT ON COLUMN po_instance.rush IS 'Whether or not this is a rush order';

COMMENT ON COLUMN po_instance.requester IS 'Who requested this material and needs to be notified on arrival';

COMMENT ON COLUMN po_instance.selector IS 'Who selected this material';

COMMENT ON COLUMN po_instance.po_number IS 'A human readable number assigned to PO';

COMMENT ON COLUMN po_instance.po_number_id IS 'UUID identifying this PO';

COMMENT ON COLUMN po_instance.po_line_number IS 'A human readable number assigned to PO line';

COMMENT ON COLUMN po_instance.po_line_id IS 'UUID identifying this purchase order line';

COMMENT ON COLUMN po_instance.vendor_code IS 'The code of the vendor';

COMMENT ON COLUMN po_instance.created_by_username IS 'Username of the user who created the record (when available)';

COMMENT ON COLUMN po_instance.po_workflow_status IS 'Workflow status of purchase order';

COMMENT ON COLUMN po_instance.status_approved IS 'Wether purchase order is approved or not';

COMMENT ON COLUMN po_instance.created_date IS 'Date when the purchase order was created';

COMMENT ON COLUMN po_instance.bill_to IS 'Name of the bill_to location of the purchase order';

COMMENT ON COLUMN po_instance.ship_to IS 'Name of the ship_to location of the purchase order';

COMMENT ON COLUMN po_instance.pol_instance_id IS 'UUID of the instance record this purchase order line is related to';

COMMENT ON COLUMN po_instance.pol_instance_hrid IS 'A human readable number of the instance record this purchase order line is related to';

COMMENT ON COLUMN po_instance.pol_holding_id IS 'UUID of the holdings this purchase order line is related to';

COMMENT ON COLUMN po_instance.pol_location_id IS 'UUID of the location created for this purcase order line';

COMMENT ON COLUMN po_instance.pol_location_name IS 'Name of the purchase order line location';

COMMENT ON COLUMN po_instance.pol_location_source IS 'Wether location is a holdings location or permanent location of the purchase order line';

COMMENT ON COLUMN po_instance.title IS 'Title of the material';

COMMENT ON COLUMN po_instance.publication_date IS 'Date (year) of the material''s publication';

COMMENT ON COLUMN po_instance.publisher IS 'Publisher of the material';

