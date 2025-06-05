/**
 * AssetService - REST API for handling lost device reports
 * Endpoint: /services/apexrest/lost
 */
@RestResource(urlMapping='/lost/*')
global with sharing class AssetService {
    
    /**
     * REST POST method for reporting lost devices
     * Accepts assetIdentifier in the request body
     * Returns claim number or appropriate message
     */
    @HttpPost
    global static String reportLost() {
        RestRequest req = RestContext.request;
        String jsonBody = req.requestBody != null ? req.requestBody.toString() : null;
        
        // Detailed request debugging
        System.debug('AssetService - Request Details:');
        System.debug('  -> RequestURI: ' + req?.requestURI);
        System.debug('  -> HTTP Method: ' + req?.httpMethod);
        System.debug('  -> Remote Address: ' + req?.remoteAddress);
        
        // Debug Headers
        if (req?.headers != null) {
            System.debug('AssetService - Request Headers:');
            for (String headerKey : req.headers.keySet()) {
                System.debug('  -> ' + headerKey + ': ' + req.headers.get(headerKey));
            }
        }
        
        // Debug Query Parameters
        Map<String, String> params = req?.params;
        if (params != null) {
            System.debug('AssetService - Query Parameters:');
            for (String paramKey : params.keySet()) {
                System.debug('  -> ' + paramKey + ': ' + params.get(paramKey));
            }
        }

        // Debug request body
        if (String.isBlank(jsonBody)) {
            return 'Request body is empty';
        }
        System.debug('DEBUG *** Request Body: ' + jsonBody);

        // Parse JSON request body
        Map<String, Object> requestMap = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        String assetIdentifier = (String) requestMap.get('assetIdentifier');
        
        // Call the service method with extracted assetIdentifier
        return reportLostDevice(assetIdentifier);
    }
    
    /**
     * Reports a device as lost and processes insurance claim if applicable
     * @param assetIdentifier The identifier of the asset to report as lost
     * @return String message indicating the result of the operation
     */
    public static String reportLostDevice(String assetIdentifier) {
        // Check if assetIdentifier is provided
        if (String.isBlank(assetIdentifier)) {
            return 'No device found.';
        }
        
        System.debug('DEBUG *** Looking for asset with identifier: ' + assetIdentifier);
        
        // Query the asset record - IMPORTANT: Use Asset_Identifier__c field!
        List<Asset> assets = [
            SELECT Id, Status
            FROM Asset 
            WHERE Asset_Identifier__c = :assetIdentifier 
            LIMIT 1
        ];

        // Debug SOQL results
        System.debug('DEBUG *** SOQL Asset query returned : ' + assets);
        
        // If no asset found, return error message
        if (assets.isEmpty()) {
            System.debug('DEBUG *** No asset found with identifier: ' + assetIdentifier);
            return 'No device found.';
        }
        
        Asset asset = assets[0];
        System.debug('DEBUG *** Found asset: ' + asset);
        
        // Check if there's already a Loss claim filed - Separate query
        List<Claim__c> existingClaims = [
            SELECT Id, Name, Type__c 
            FROM Claim__c 
            WHERE Asset__c = :asset.Id 
            AND Type__c = 'Loss'
            LIMIT 1
        ];
        
        System.debug('DEBUG *** Existing claims check returned: ' + existingClaims);
        
        // If a loss claim already exists, return message with claim number
        if (!existingClaims.isEmpty()) {
            System.debug('DEBUG *** Found existing claim: ' + existingClaims[0]);
            return existingClaims[0].Name + ' already filed.';
        }
        
        // Update asset status to 'Lost'
        asset.Status = 'Lost';
        update asset;
        System.debug('DEBUG *** Updated asset status to Lost');
        
        // Check if the asset has active comprehensive insurance coverage
        List<Insurance__c> insurances = [
            SELECT Id 
            FROM Insurance__c 
            WHERE Asset__c = :asset.Id 
            AND Coverage__c = 'Comprehensive' 
            AND Active__c = true
            LIMIT 1
        ];
        
        System.debug('DEBUG *** Insurance check returned: ' + insurances);
        
        // If no active comprehensive coverage, return message
        if (insurances.isEmpty()) {
            System.debug('DEBUG *** No active comprehensive insurance found');
            return 'No coverage. Asset status adjusted to Lost.';
        }
        
        // Create a new claim record
        Claim__c newClaim = new Claim__c(
            Asset__c = asset.Id,
            Type__c = 'Loss',
            Status__c = 'New',
            Insurance__c = insurances[0].Id
        );
        
        insert newClaim;
        System.debug('DEBUG *** Created new claim: ' + newClaim);
        
        // Query to get the claim number (Name field)
        newClaim = [SELECT Name FROM Claim__c WHERE Id = :newClaim.Id];
        System.debug('DEBUG *** Returning claim number: ' + newClaim.Name);
        
        // Return the claim number
        return newClaim.Name;
    }
}