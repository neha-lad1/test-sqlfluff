 
BEGIN
DBMS_CLOUD.CREATE_EXTERNAL_TABLE (
    table_name => 'SWCC_SOURCE',
    file_uri_list => 'https://objectstorage.me-jeddah-1.oraclecloud.com/p/5LoD14kbik9180oPLVNwEYvArqdpfqD7jpdFZ2uz_OdMvgpptEU2HllBbI9pccyh/n/axjj8sdvrg1w/b/bkt-neom-enowa-synergyze-dev-data-raw/o/ENOWA/WATER/MIDSTREAM/SHAREPOINT/SWCC/*.parquet',
    format => '{"type": "parquet", "schema": "first"}'
);
END;
/
