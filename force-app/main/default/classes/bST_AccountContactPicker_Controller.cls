/*
*********************************************************
Apex Class Name    : bST_AccountContactPicker_Controller
Created Date       : March 9th, 2025
@description       : This class provides methods to fetch contacts related to 
                     an account and count total contacts. It includes exception 
                     handling for invalid input scenarios.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                         Modification
1.0   09-03-2025   Irfan Ali                      Initial Version
1.1   10-03-2025   Irfan Ali                      Added fetchTotalContactsCount method for pagination
*********************************************************
*/

public with sharing class bST_AccountContactPicker_Controller {

    public static final String EXCEPTION_MESSAGE = 'An error occurred while fetching contacts.';
    public static final String EXCEPTION_MESSAGE_FOR_NULL_ACCOUNTID = 'AccountId cannot be null.';
    public static final String EXCEPTION_MESSAGE_FOR_DEVELOPER = 'Exception in ';
    
    /*
    *********************************************************
    @Method Name    : fetchContactsByAccount
    @description    : Fetches a list of contacts associated with the given account.
                      Supports optional search filtering and pagination.
    @param          : accountId - ID of the Account
                      limitSize - Number of records to fetch
                      offsetSize - Number of records to skip
                      searchKey - Search filter for name, email, or phone
    @return         : List<Contact>
    ********************************************************
    */

    @AuraEnabled
    public static List<Contact> fetchContactsByAccount(Id accountId, Integer limitSize, Integer offsetSize, String searchKey) {
        if (accountId == null) {
            throw new AuraHandledException(EXCEPTION_MESSAGE_FOR_NULL_ACCOUNTID);
        }

        try {
            List<Contact> contacts = new List<Contact>();

            String query = 'SELECT Id, Name, Email, Phone FROM Contact WHERE AccountId = :accountId';
            
            if (String.isNotBlank(searchKey)) {
                searchKey = '%' + String.escapeSingleQuotes(searchKey) + '%';
                query += ' AND (Name LIKE :searchKey OR Email LIKE :searchKey OR Phone LIKE :searchKey)';
            }

            query += ' ORDER BY Name ASC LIMIT :limitSize';

            if (offsetSize != null && offsetSize > 0) {
                query += ' OFFSET :offsetSize';
            }

            contacts = Database.query(query);
            return contacts;
        } catch (Exception e) {
            throw new AuraHandledException(EXCEPTION_MESSAGE_FOR_DEVELOPER +'fetchContactsByAccount: ' + e.getMessage());
        }
    }


    /*
    *********************************************************
    @Method Name    : fetchTotalContactsCount
    @description    : Fetches the total number of contacts associated with an account.
                      Supports optional search filtering.
    @param          : accountId - ID of the Account
                      searchKey - Search filter for name, email, or phone
    @return         : Integer - Total count of matching contacts
    ********************************************************
    */

    @AuraEnabled(cacheable=true)
    public static Integer fetchTotalContactsCount(Id accountId, String searchKey) {
        if (accountId == null) {
            throw new AuraHandledException(EXCEPTION_MESSAGE_FOR_NULL_ACCOUNTID);
        }

        try {
            Integer count;
            String query = 'SELECT COUNT() FROM Contact WHERE AccountId = :accountId';

            if (String.isNotBlank(searchKey)) {
                searchKey = '%' + String.escapeSingleQuotes(searchKey) + '%';
                query += ' AND (Name LIKE :searchKey OR Email LIKE :searchKey OR Phone LIKE :searchKey)';
            }

            count = (Integer) Database.countQuery(query);
            return count;
        } catch (Exception e) {
            throw new AuraHandledException(EXCEPTION_MESSAGE_FOR_DEVELOPER +'fetchTotalContactsCount: ' + e.getMessage());
        }
    }
}
