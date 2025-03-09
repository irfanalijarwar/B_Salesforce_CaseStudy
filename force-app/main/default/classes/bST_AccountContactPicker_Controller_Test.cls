/*
*********************************************************
Apex Class Name    : bST_AccountContactPicker_Controller_Test
Created Date       : March 9th, 2025
@description       : This test class verifies the functionality of the 
                     bST_AccountContactPicker_Controller class. It covers scenarios 
                     for fetching contacts based on account, handling exceptions for 
                     invalid inputs, and validating cases where no contacts exist.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                         Modification
1.0   09-03-2025   Irfan Ali                      Initial Version
*********************************************************
*/

@isTest(seeAllData=false)
public with sharing class bST_AccountContactPicker_Controller_Test {

    /*
    *********************************************************
    @Method Name    : setupTestData
    @description    : This method sets up test data required for the test 
                      methods. It creates test Accounts, including one with contacts 
                      and one without contacts.
    @param          : None
    @return         : void
    ********************************************************
    */

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Account emptyAccount = new Account(Name = 'Empty Account');
        insert emptyAccount;
        
        List<Contact> contacts = new List<Contact>{
            new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@example.com', Phone = '1234567890', AccountId = testAccount.Id),
            new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'jane.doe@example.com', Phone = '0987654321', AccountId = testAccount.Id)
        };
        insert contacts;
    }

     /*
    *********************************************************
    @Method Name    : testFetchContactsByAccount
    @description    : Tests fetching contacts for a valid account with contacts.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchContactsByAccount() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<Contact> result = bST_AccountContactPicker_Controller.fetchContactsByAccount(testAccount.Id, 10, 0, null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(2, result.size(), 'Expected 2 contacts to be returned');
    }
    
    /*
    *********************************************************
    @Method Name    : testFetchContactsByAccountWithSearch
    @description    : Tests fetching contacts using a search key.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchContactsByAccountWithSearch() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<Contact> result = bST_AccountContactPicker_Controller.fetchContactsByAccount(testAccount.Id, 10, 0, 'John');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Expected 1 contact to be returned with search key "John"');
    }
    
    /*
    *********************************************************
    @Method Name    : testFetchContactsByAccountWithPagination
    @description    : Tests fetching contacts for an account with pagination.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchContactsByAccountWithPagination() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        List<Contact> result = bST_AccountContactPicker_Controller.fetchContactsByAccount(testAccount.Id, 1, 1, null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(1, result.size(), 'Expected 1 contact due to pagination');
    }

       /*
    *********************************************************
    @Method Name    : testFetchContactsByAccountWithNoContacts
    @description    : Tests fetching contacts for an account with no contacts.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchContactsByAccountWithNoContacts() {
        Account emptyAccount = [SELECT Id FROM Account WHERE Name = 'Empty Account' LIMIT 1];
        
        Test.startTest();
        List<Contact> result = bST_AccountContactPicker_Controller.fetchContactsByAccount(emptyAccount.Id, 10, 0, null);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.size(), 'Expected 0 contacts for an account with no contacts');
    }
    
    /*
    *********************************************************
    @Method Name    : testFetchContactsByAccountWithNullAccountId
    @description    : Tests fetching contacts with a null AccountId, expecting an exception.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchContactsByAccountWithNullAccountId() {
        Test.startTest();
        try {
            bST_AccountContactPicker_Controller.fetchContactsByAccount(null, 10, 0, null);
            Assert.fail('Exception should have been thrown for null AccountId');
        } catch (AuraHandledException e) {
            Assert.areEqual('Script-thrown exception', e.getMessage(), 'Expected exception message does not match');
        }
        Test.stopTest();
    }

    /*
    *********************************************************
    @Method Name    : testFetchContactsByAccountWithException
    @description    : Tests fetching contacts with an invalid limit value, expecting an exception.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchContactsByAccountWithException() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Test.startTest();
        try {
            bST_AccountContactPicker_Controller.fetchContactsByAccount(testAccount.Id, -1, 0, null);
            Assert.fail('Exception should have been thrown for invalid limit');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Script-thrown exception'), 'Expected developer exception message');
        }
        Test.stopTest();
    }
    
    /*
    *********************************************************
    @Method Name    : testFetchTotalContactsCount
    @description    : Tests fetching the total count of contacts for a valid account.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchTotalContactsCount() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        Integer count = bST_AccountContactPicker_Controller.fetchTotalContactsCount(testAccount.Id, null);
        Test.stopTest();
        
        Assert.areEqual(2, count, 'Expected 2 contacts in count');
    }    

    /*
    *********************************************************
    @Method Name    : testFetchTotalContactsCountWithSearch
    @description    : Tests fetching the total contact count with a search filter.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchTotalContactsCountWithSearch() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        
        Test.startTest();
        Integer count = bST_AccountContactPicker_Controller.fetchTotalContactsCount(testAccount.Id, 'Jane');
        Test.stopTest();
        
        Assert.areEqual(1, count, 'Expected 1 contact count with search key "Jane"');
    }
    
    /*
    *********************************************************
    @Method Name    : testFetchTotalContactsCountWithNullAccountId
    @description    : Tests fetching the total contacts count with a null AccountId, expecting an exception.
    @param          : None
    @return         : void
    ********************************************************
    */

    @isTest
    static void testFetchTotalContactsCountWithNullAccountId() {
        Test.startTest();
        try {
            bST_AccountContactPicker_Controller.fetchTotalContactsCount(null, null);
            Assert.fail('Exception should have been thrown for null AccountId');
        } catch (AuraHandledException e) {
            Assert.areEqual('Script-thrown exception', e.getMessage(), 'Expected exception message does not match');
        }
        Test.stopTest();
    }
}