/**
 * CredentialVerificationService - SOAP Web Service for verifying drone operator certifications
 * Allows third parties (realtors) to verify certification status of registered drone operators
 */
global with sharing class CredentialVerificationService {
    
    /**
     * SOAP Web Service method to verify credential status
     * @param contactLastName The last name of the contact (drone operator)
     * @param certificationName The unique name of the contact certification
     * @return String indicating certification status: 'Valid', 'Needs Renewal', or 'No record found'
     */
    webservice static String verifyCredential(String contactLastName, String certificationName) {
        
        // Input validation
        if (String.isBlank(contactLastName) || String.isBlank(certificationName)) {
            System.debug('CredentialVerificationService - Invalid input parameters');
            System.debug('  -> contactLastName: ' + contactLastName);
            System.debug('  -> certificationName: ' + certificationName);
            return 'No record found';
        }
        
        System.debug('CredentialVerificationService - Verifying credential:');
        System.debug('  -> Contact Last Name: ' + contactLastName);
        System.debug('  -> Certification Name: ' + certificationName);
        
        try {
            // Query for the Contact Certification record
            // Join Contact and Contact_Certification__c to verify both contact and certification exist
            List<Contact_Certification__c> contactCertifications = [
                SELECT Id, Name, isActive__c, Contact__r.LastName
                FROM Contact_Certification__c 
                WHERE Contact__r.LastName = :contactLastName 
                AND Name = :certificationName
                LIMIT 1
            ];
            
            System.debug('CredentialVerificationService - Query results: ' + contactCertifications);
            
            // If no record found, return appropriate message
            if (contactCertifications.isEmpty()) {
                System.debug('CredentialVerificationService - No matching record found');
                return 'No record found';
            }
            
            Contact_Certification__c contactCert = contactCertifications[0];
            System.debug('CredentialVerificationService - Found certification record:');
            System.debug('  -> ID: ' + contactCert.Id);
            System.debug('  -> Name: ' + contactCert.Name);
            System.debug('  -> isActive: ' + contactCert.isActive__c);
            System.debug('  -> Contact Last Name: ' + contactCert.Contact__r.LastName);
            
            // Check if certification is active
            if (contactCert.isActive__c == true) {
                System.debug('CredentialVerificationService - Certification is active - returning Valid');
                return 'Valid';
            } else {
                System.debug('CredentialVerificationService - Certification is not active - returning Needs Renewal');
                return 'Needs Renewal';
            }
            
        } catch (Exception e) {
            // Log the exception for debugging
            System.debug('CredentialVerificationService - Exception occurred: ' + e.getMessage());
            System.debug('CredentialVerificationService - Stack trace: ' + e.getStackTraceString());
            
            // Return generic error message to maintain security
            return 'No record found';
        }
    }
}