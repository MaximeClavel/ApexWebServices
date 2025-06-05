/**
 * Test class for AssetService REST API
 * Tests all scenarios for reporting lost devices and insurance claims
 */
@isTest
public class AssetServiceTest {
    
    /**
     * Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create a test account
        Account testAccount = new Account(
            Name = 'Test Account for Assets'
        );
        insert testAccount;
        
        // Create test assets
        List<Asset> testAssets = new List<Asset>();
        
        // Asset with comprehensive insurance
        Asset assetWithInsurance = new Asset(
            Name = 'Test Drone 1',
            Asset_Identifier__c = 'DRONE001',
            Status = 'Active',
            AccountId = testAccount.Id
        );
        testAssets.add(assetWithInsurance);
        
        // Asset without insurance
        Asset assetWithoutInsurance = new Asset(
            Name = 'Test Drone 2',
            Asset_Identifier__c = 'DRONE002',
            Status = 'Active',
            AccountId = testAccount.Id
        );
        testAssets.add(assetWithoutInsurance);
        
        // Asset with existing loss claim
        Asset assetWithExistingClaim = new Asset(
            Name = 'Test Drone 3',
            Asset_Identifier__c = 'DRONE003',
            Status = 'Lost',
            AccountId = testAccount.Id
        );
        testAssets.add(assetWithExistingClaim);
        
        insert testAssets;
        
        // Create comprehensive insurance for first asset
        Insurance__c comprehensiveInsurance = new Insurance__c(
            Asset__c = assetWithInsurance.Id,
            Coverage__c = 'Comprehensive',
            Active__c = true
        );
        insert comprehensiveInsurance;
        
        // Create existing loss claim for third asset
        Claim__c existingClaim = new Claim__c(
            Asset__c = assetWithExistingClaim.Id,
            Type__c = 'Loss',
            Status__c = 'New'
        );
        insert existingClaim;
    }
    
    /**
     * Test REST API with valid asset that has comprehensive insurance
     * Should create claim and return claim number
     */
    @isTest
    static void testReportLost_ValidAssetWithInsurance() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"assetIdentifier": "DRONE001"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String result = AssetService.reportLost();
        Test.stopTest();
        
        // Verify claim was created and claim number returned
        System.assertNotEquals(null, result, 'Should return a claim number');
        System.assertNotEquals('', result, 'Should return a non-empty claim number');
        System.assert(!result.contains('No device found'), 'Should not return error message');
        System.assert(!result.contains('No coverage'), 'Should not return no coverage message');
        
        // Verify asset status updated to Lost
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'DRONE001'];
        System.assertEquals('Lost', updatedAsset.Status, 'Asset status should be updated to Lost');
        
        // Verify claim record was created
        List<Claim__c> claims = [SELECT Name, Type__c, Status__c FROM Claim__c WHERE Asset__c = :updatedAsset.Id];
        System.assertEquals(1, claims.size(), 'One claim should be created');
        System.assertEquals('Loss', claims[0].Type__c, 'Claim type should be Loss');
        System.assertEquals('New', claims[0].Status__c, 'Claim status should be New');
    }
    
    /**
     * Test REST API with asset that has no insurance coverage
     * Should update status to Lost and return no coverage message
     */
    @isTest
    static void testReportLost_AssetWithoutInsurance() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"assetIdentifier": "DRONE002"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String result = AssetService.reportLost();
        Test.stopTest();
        
        // Verify correct message returned
        System.assertEquals('No coverage. Asset status adjusted to Lost.', result, 'Should return no coverage message');
        
        // Verify asset status updated to Lost
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'DRONE002'];
        System.assertEquals('Lost', updatedAsset.Status, 'Asset status should be updated to Lost');
        
        // Verify no claim was created
        List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Asset__c = :updatedAsset.Id];
        System.assertEquals(0, claims.size(), 'No claim should be created without insurance');
    }
    
    /**
     * Test REST API with asset that already has a loss claim
     * Should return existing claim number with "already filed" message
     */
    @isTest
    static void testReportLost_ExistingClaim() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"assetIdentifier": "DRONE003"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String result = AssetService.reportLost();
        Test.stopTest();
        
        // Verify correct message returned with existing claim number
        System.assert(result.contains('already filed.'), 'Should return already filed message');
        
        // Get the actual claim number to verify it's included in the response
        Asset testAsset = [SELECT Id FROM Asset WHERE Asset_Identifier__c = 'DRONE003'];
        Claim__c existingClaim = [SELECT Name FROM Claim__c WHERE Asset__c = :testAsset.Id AND Type__c = 'Loss' LIMIT 1];
        System.assert(result.contains(existingClaim.Name), 'Should include the actual claim number in response');
        
        // Verify only one claim exists (the original one)
        List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Asset__c = :testAsset.Id AND Type__c = 'Loss'];
        System.assertEquals(1, claims.size(), 'Should still have only one claim');
    }
    
    /**
     * Test REST API with invalid/non-existent asset identifier
     * Should return "No device found." message
     */
    @isTest
    static void testReportLost_InvalidAssetIdentifier() {
        // Setup REST context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"assetIdentifier": "INVALID123"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String result = AssetService.reportLost();
        Test.stopTest();
        
        // Verify correct error message returned
        System.assertEquals('No device found.', result, 'Should return no device found message');
    }
    
    /**
     * Test REST API with empty request body
     * Should return "Request body is empty" message
     */
    @isTest
    static void testReportLost_EmptyRequestBody() {
        // Setup REST context with empty body
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = null;
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String result = AssetService.reportLost();
        Test.stopTest();
        
        // Verify correct error message returned
        System.assertEquals('Request body is empty', result, 'Should return empty body message');
    }
    
    /**
     * Test REST API with missing assetIdentifier in JSON
     * Should return "No device found." message
     */
    @isTest
    static void testReportLost_MissingAssetIdentifier() {
        // Setup REST context with JSON missing assetIdentifier
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/lost/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"otherField": "value"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String result = AssetService.reportLost();
        Test.stopTest();
        
        // Verify correct error message returned
        System.assertEquals('No device found.', result, 'Should return no device found message');
    }
    
    /**
     * Test direct method call with valid asset that has comprehensive insurance
     * Should create claim and return claim number
     */
    @isTest
    static void testReportLostDevice_ValidAssetWithInsurance() {
        Test.startTest();
        String result = AssetService.reportLostDevice('DRONE001');
        Test.stopTest();
        
        // Verify claim number returned
        System.assertNotEquals(null, result, 'Should return a claim number');
        System.assertNotEquals('', result, 'Should return a non-empty claim number');
        System.assert(!result.contains('No device found'), 'Should not return error message');
        System.assert(!result.contains('No coverage'), 'Should not return no coverage message');
        
        // Verify asset status updated
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'DRONE001'];
        System.assertEquals('Lost', updatedAsset.Status, 'Asset status should be updated to Lost');
    }
    
    /**
     * Test direct method call with null/empty asset identifier
     * Should return "No device found." message
     */
    @isTest
    static void testReportLostDevice_NullAssetIdentifier() {
        Test.startTest();
        String result1 = AssetService.reportLostDevice(null);
        String result2 = AssetService.reportLostDevice('');
        String result3 = AssetService.reportLostDevice('   ');
        Test.stopTest();
        
        // Verify all return correct error message
        System.assertEquals('No device found.', result1, 'Should return no device found for null');
        System.assertEquals('No device found.', result2, 'Should return no device found for empty string');
        System.assertEquals('No device found.', result3, 'Should return no device found for whitespace');
    }
    
    /**
     * Test with asset that has inactive comprehensive insurance
     * Should not create claim and return no coverage message
     */
    @isTest
    static void testReportLostDevice_InactiveInsurance() {
        // Get the test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Assets' LIMIT 1];
        
        // Create asset with inactive insurance
        Asset testAsset = new Asset(
            Name = 'Test Drone Inactive',
            Asset_Identifier__c = 'DRONE004',
            Status = 'Active',
            AccountId = testAccount.Id
        );
        insert testAsset;
        
        Insurance__c inactiveInsurance = new Insurance__c(
            Asset__c = testAsset.Id,
            Coverage__c = 'Comprehensive',
            Active__c = false  // Inactive insurance
        );
        insert inactiveInsurance;
        
        Test.startTest();
        String result = AssetService.reportLostDevice('DRONE004');
        Test.stopTest();
        
        // Verify no coverage message returned
        System.assertEquals('No coverage. Asset status adjusted to Lost.', result, 'Should return no coverage message');
        
        // Verify asset status updated but no claim created
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'DRONE004'];
        System.assertEquals('Lost', updatedAsset.Status, 'Asset status should be updated to Lost');
        
        List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Asset__c = :updatedAsset.Id];
        System.assertEquals(0, claims.size(), 'No claim should be created with inactive insurance');
    }
    
    /**
     * Test with asset that has non-comprehensive insurance
     * Should not create claim and return no coverage message
     */
    @isTest
    static void testReportLostDevice_NonComprehensiveInsurance() {
        // Get the test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for Assets' LIMIT 1];
        
        // Create asset with basic insurance (not comprehensive)
        Asset testAsset = new Asset(
            Name = 'Test Drone Basic',
            Asset_Identifier__c = 'DRONE005',
            Status = 'Active',
            AccountId = testAccount.Id
        );
        insert testAsset;
        
        Insurance__c basicInsurance = new Insurance__c(
            Asset__c = testAsset.Id,
            Coverage__c = 'Liability',  // Use Liability instead of Basic
            Active__c = true
        );
        insert basicInsurance;
        
        Test.startTest();
        String result = AssetService.reportLostDevice('DRONE005');
        Test.stopTest();
        
        // Verify no coverage message returned
        System.assertEquals('No coverage. Asset status adjusted to Lost.', result, 'Should return no coverage message');
        
        // Verify asset status updated but no claim created
        Asset updatedAsset = [SELECT Status FROM Asset WHERE Asset_Identifier__c = 'DRONE005'];
        System.assertEquals('Lost', updatedAsset.Status, 'Asset status should be updated to Lost');
        
        List<Claim__c> claims = [SELECT Id FROM Claim__c WHERE Asset__c = :updatedAsset.Id];
        System.assertEquals(0, claims.size(), 'No claim should be created with liability insurance only');
    }
}