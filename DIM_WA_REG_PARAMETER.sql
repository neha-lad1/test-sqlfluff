BEGIN
DBMS_CLOUD.CREATE_EXTERNAL_TABLE (
    table_name => 'DIM_WA_REG_PARAMETER',
    file_uri_list => 'https://objectstorage.me-jeddah-1.oraclecloud.com/p/mKOwh2AcooZdMp0nwmksjgqnvFUUCu4rbxRr-us9vzYE9R-7Lr5fs4xYG9OUB6JW/n/axjj8sdvrg1w/b/bkt-neom-enowa-synergyze-dev-data-curated/o/ENOWA/WATER/REGULATION/DIM_WA_REG_PARAMETER/*.parquet',
    format => '{"type": "parquet", "schema": "first"}'
);
END;
/