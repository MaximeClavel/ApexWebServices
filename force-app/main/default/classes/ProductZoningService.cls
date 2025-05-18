/**
 * @description Apex REST service for determining permissible fly zones for products
 */
@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
    
    /** 
     * @description Handles GET requests to determine permissible fly zones
     * @return String The permissible fly zone or appropriate message
     */
    @HttpGet
    global static String getPermissibleFlyZone() {
        try {
            RestRequest req = RestContext.request;
            
            // Detailed request debugging
            System.debug('ProductZoningService - Request Details:');
            System.debug('  -> RequestURI: ' + req?.requestURI);
            System.debug('  -> HTTP Method: ' + req?.httpMethod);
            System.debug('  -> Remote Address: ' + req?.remoteAddress);
            
            // Debug Headers
            if (req?.headers != null) {
                System.debug('ProductZoningService - Request Headers:');
                for (String headerKey : req.headers.keySet()) {
                    System.debug('  -> ' + headerKey + ': ' + req.headers.get(headerKey));
                }
            }
            
            // Debug Query Parameters
            Map<String, String> params = req?.params;
            if (params != null) {
                System.debug('ProductZoningService - Query Parameters:');
                for (String paramKey : params.keySet()) {
                    System.debug('  -> ' + paramKey + ': ' + params.get(paramKey));
                }
            }
            
            // Validate request
            if (req == null || req.headers == null || req.params == null) {
                System.debug('ProductZoningService - Invalid request: Missing required components');
                return 'Invalid request: Missing required components';
            }
            
            // Get the CountryCode from headers, default to US if not provided
            String countryCode = 'US';
            if (req.headers.containsKey('CountryCode')) {
                countryCode = req.headers.get('CountryCode');
                System.debug('ProductZoningService - Country code from header: ' + countryCode);
            } else {
                System.debug('ProductZoningService - Using default country code: ' + countryCode);
            }
            
            // Get the ProductCode from query parameters
            String productCode = null;
            if (params.containsKey('ProductCode')) {
                productCode = params.get('ProductCode');
                System.debug('ProductZoningService - Product code from query parameter: ' + productCode);
            }
            
            if (String.isBlank(productCode)) {
                System.debug('ProductZoningService - Invalid request: Missing product code');
                return 'ProductCode is missing or doesn\'t exist';
            }
        
            // Query for the product based on the ProductCode
            List<Product2> products = [
                SELECT Id, Family 
                FROM Product2 
                WHERE ProductCode = :productCode 
                LIMIT 1
            ];
            System.debug('ProductZoningService - Product query result: ' + products);
            
            if (products.isEmpty()) {
                System.debug('ProductZoningService - No product found for code: ' + productCode);
                return 'ProductCode is missing or doesn\'t exist';
            }
            
            // Get the product family
            String productFamily = products[0].Family;
            System.debug('ProductZoningService - Product family: ' + productFamily);
            
            // Query the Product Geo Mapping metadata for this family and country
            List<Product_Geo_Mapping__mdt> geoMappings = [
                SELECT Permissible_Fly_Zone__c 
                FROM Product_Geo_Mapping__mdt 
                WHERE Product_Family__c = :productFamily 
                AND Country_Code__c = :countryCode
                LIMIT 1
            ];
            System.debug('ProductZoningService - Geo mapping query result: ' + geoMappings);
            
            // If there's no mapping for this country, instruct to check with local authorities
            if (geoMappings.isEmpty()) {
                System.debug('ProductZoningService - No geo mapping found for family: ' + productFamily + ' and country: ' + countryCode);
                return 'Confirm with the local authorities';
            }
            
            // Return the permissible fly zone
            System.debug('ProductZoningService - Returning fly zone: ' + geoMappings[0].Permissible_Fly_Zone__c);
            return geoMappings[0].Permissible_Fly_Zone__c;
            
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ProductZoningService - Exception: ' + ex.getMessage() + '\n' + ex.getStackTraceString());
            return 'ProductCode is missing or doesn\'t exist';
        }
    }
}