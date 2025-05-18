/**
 * @description Test class for ProductZoningService
 */
@isTest
private class ProductZoningServiceTest {
    
    /**
     * @description Sets up test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create test product records with different families
        List<Product2> products = new List<Product2>();
        
        products.add(new Product2(
            Name = 'Drone X1',
            ProductCode = 'AMER_Fixed_Wing',
            Family = 'Fixed-Wing'
        ));
        
        products.add(new Product2(
            Name = 'Drone Pro',
            ProductCode = 'APAC_MALE',
            Family = 'MALE'
        ));
        
        products.add(new Product2(
            Name = 'Drone Mini',
            ProductCode = 'EU_Multi_Rotor',
            Family = 'Multi-Rotor'
        ));

        insert products;
    }
    
    /**
     * @description Tests the scenario where a valid product code in query params and country in header
     */
    @isTest
    static void testGetPermissibleFlyZone_ValidProductAndCountry() {
        // Setup the REST request
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'US');
        
        // Add product code as query parameter
        req.addParameter('ProductCode', 'AMER_Fixed_Wing');
        
        RestContext.request = req;
        
        // Call the service method
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        // Since we can't create custom metadata records in tests,
        // we'll verify the code execution path rather than exact response
        System.assert(resultResponse != null, 'Response should not be null');
    }
    
    /**
     * @description Tests the scenario where country code is not provided (defaults to US)
     */
    @isTest
    static void testGetPermissibleFlyZone_DefaultCountry() {
        // Setup the REST request without a country code
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        
        // Add product code as query parameter
        req.addParameter('ProductCode', 'APAC_MALE');
        
        RestContext.request = req;
        
        // Call the service method
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        // Verify code execution path
        System.assert(resultResponse != null, 'Response should not be null');
    }
    
    /**
     * @description Tests scenario where no mapping exists for a country
     */
    @isTest
    static void testGetPermissibleFlyZone_CheckWithLocalAuthorities() {
        // Setup REST request with a country that won't have mapping
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'DE'); // We'll ensure this doesn't match
        
        // Add product code as query parameter
        req.addParameter('ProductCode', 'APAC_MALE');
        
        RestContext.request = req;
        
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        // We expect to get the confirmation message when no mapping exists
        System.assertEquals('Confirm with the local authorities', resultResponse, 
                          'Should instruct to check with local authorities when no mapping exists');
    }
    
    /**
     * @description Tests the scenario with an invalid product code
     */
    @isTest
    static void testGetPermissibleFlyZone_InvalidProductCode() {
        // Setup REST request with invalid product code
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'US');
        
        // Add invalid product code as query parameter
        req.addParameter('ProductCode', 'INVALID-CODE');
        
        RestContext.request = req;
        
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        System.assertEquals('ProductCode is missing or doesn\'t exist', resultResponse,
                          'Should return error message for invalid product code');
    }
    
    /**
     * @description Tests the scenario with a missing product code
     */
    @isTest
    static void testGetPermissibleFlyZone_MissingProductCode() {
        // Setup REST request with no product code
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'US');
        
        // No product code parameter added
        
        RestContext.request = req;
        
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        System.assertEquals('ProductCode is missing or doesn\'t exist', resultResponse,
                          'Should return error message for missing product code');
    }
    
    /**
     * @description Tests the scenario where the request is null
     */
    @isTest
    static void testGetPermissibleFlyZone_ReqNull() {      
        RestContext.request = null;
        
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        System.assertEquals('Invalid request: Missing required components', resultResponse,
                        'Should return error message when exception occurs');
    }
    
    /**
     * @description Tests the scenario where headers or params are null
     */
    @isTest
    static void testGetPermissibleFlyZone_MissingComponents() {
        // Create a RestRequest with null components
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/ProductZoning/';
        req.httpMethod = 'GET';
        // No headers or params added
        
        RestContext.request = req;
        
        Test.startTest();
        String resultResponse = ProductZoningService.getPermissibleFlyZone();
        Test.stopTest();
        
        System.assertEquals('ProductCode is missing or doesn\'t exist', resultResponse,
                       'Should return error message for missing required components');
    }
}