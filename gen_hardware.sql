SELECT 
  DISTINCT(RackObject.name) AS NAME, 
  Object.id AS 'Object ID',
  INET_NTOA(console.ip) AS Console,
  TagTree.tag AS TAG, 
  RackObject.label AS LABEL, 
--  RackObject.asset_no AS ASSET_TAG, 
  Attr_Serial.string_value AS SERIAL, 
  Attr_SWVer.string_value AS 'SW Version', 
  FROM_UNIXTIME(Attr_Support.uint_value+84600, '%Y-%m-%d') AS 'Support End Date', 
  Dictionary.dict_value AS TYPE, 
  dictmodel.dict_value AS MODEL, 
  RackObject.comment AS COMMENT, 
  Rack.name AS RACK
--  INET_NTOA(ipv4.ip) AS IPv4addr
FROM RackObject
  LEFT JOIN RackSpace ON RackSpace.object_id = RackObject.id
  LEFT JOIN Object ON Object.id = RackObject.id
  LEFT JOIN IPv4Allocation AS console ON (console.object_id = RackObject.id and console.name = 'kvm')
  LEFT JOIN Rack ON RackSpace.rack_id = Rack.id
  LEFT JOIN TagStorage ON (TagStorage.entity_id = RackObject.id AND TagStorage.entity_realm = 'object')
  LEFT JOIN TagTree ON TagStorage.tag_id = TagTree.id
  LEFT JOIN AttributeValue AS Attr_Serial ON (Attr_Serial.object_id = RackObject.id AND Attr_Serial.attr_id = 1)
  LEFT JOIN AttributeValue AS Attr_SWVer ON (Attr_SWVer.object_id = RackObject.id AND Attr_SWVer.attr_id = 5)
  LEFT JOIN AttributeValue AS Attr_Support ON (Attr_Support.object_id = RackObject.id AND Attr_Support.attr_id = 21)
  LEFT JOIN Dictionary ON Dictionary.dict_key = RackObject.objtype_id
  LEFT JOIN AttributeValue AS avmodel ON (avmodel.object_id = RackObject.id AND avmodel.attr_id = 2)
  LEFT JOIN Dictionary AS dictmodel ON dictmodel.dict_key = avmodel.uint_value
--  LEFT JOIN IPv4Allocation AS ipv4 ON ipv4.object_id = RackObject.id
WHERE 
  RackObject.objtype_id != 50004 AND 
  TagTree.tag = '$TAGID'
ORDER BY
  RackObject.name;
