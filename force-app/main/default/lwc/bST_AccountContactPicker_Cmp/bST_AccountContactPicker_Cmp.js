/*
*********************************************************
LWC Component Name : BST_AccountContactPicker_Cmp
Created Date       : March 9th, 2025
@description       : This Lightning Web Component is used to fetch and display 
                     contacts related to an account. It supports pagination, 
                     sorting, and searching functionality.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                         Modification
1.0   09-03-2025   Irfan Ali                      Initial Version
1.1   10-03-2025   Irfan Ali                      Implemented pagination
*********************************************************
*/

import { LightningElement, track, wire } from 'lwc';
import { getListUi } from 'lightning/uiListApi';
import { getFieldValue } from 'lightning/uiRecordApi';
import getContactsByAccount from '@salesforce/apex/bST_AccountContactPicker_Controller.fetchContactsByAccount';
import getTotalContactsCount from '@salesforce/apex/bST_AccountContactPicker_Controller.fetchTotalContactsCount';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BST_AccountContactPicker_Cmp extends LightningElement {
    @track accounts = [];
    selectedAccountId = '';
    @track contacts = [];
    isModalOpen = false;
    selectedContactId = '';
    searchKey = '';
    currentOffset = 0;
    totalContacts = 0;
    pageSize = 5;
    sortBy = 'Name';
    sortDirection = 'asc';

    updatedContactsMap = new Map();

    columns = [
        { label: '#', fieldName: 'index', type: 'number', initialWidth: 50 },
        { 
            label: 'Name', 
            fieldName: 'contactUrl', 
            type: 'url', 
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, 
            sortable: true 
        },
        { label: 'Email', fieldName: 'Email', type: 'email', sortable: true },
        { label: 'Phone', fieldName: 'Phone', type: 'phone', sortable: true },
        { type: 'button', typeAttributes: { label: 'Edit', name: 'edit', variant: 'brand' } }
    ];

    get currentPageNumber() {
        return Math.floor(this.currentOffset / this.pageSize) + 1;
    }

    get isNextDisabled() {
        return this.currentOffset + this.pageSize >= this.totalContacts;
    }

    get isPreviousDisabled() {
        return this.currentOffset === 0;
    }


      /*
    *********************************************************
    @Method Name    : wiredAccounts
    @description    : Fetches the list of accounts from Salesforce.
    @param          : None
    @return         : void
    ********************************************************
    */

    @wire(getListUi, { objectApiName: ACCOUNT_OBJECT, listViewApiName: 'AllAccounts' })
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data.records.records.map(acc => ({
                label: getFieldValue(acc, ACCOUNT_NAME),
                value: acc.id
            }));
        } else if (error) {
            if(error.body.message == 'The requested resource does not exist') {
                this.showToast('Error', 'List view not found. Please create list view on Account by name AllAccounts', 'error');
                console.error('Error fetching accounts:', error);
            }
            else{
                this.showToast('Error', 'Error fetching accounts.', 'error');
                console.error('Error fetching accounts:', error);
            }
        }
    }


    /*
    *********************************************************
    @Method Name    : fetchTotalContacts
    @description    : Fetches the total number of contacts for the selected account.
    @param          : None
    @return         : void
    ********************************************************
    */

    async fetchTotalContacts() {
        if (!this.selectedAccountId) return;
        try {
            this.totalContacts = await getTotalContactsCount({ accountId: this.selectedAccountId, searchKey: this.searchKey });
        } catch (error) {
            this.showToast('Error', 'Error fetching contact count.', 'error');
            console.error('Error fetching contact count:', error);
        }
    }


    /*
    *********************************************************
    @Method Name    : fetchContacts
    @description    : Fetches contacts for the selected account with pagination.
    @param          : None
    @return         : void
    ********************************************************
    */

    async fetchContacts() {
        if (!this.selectedAccountId) return;

        try {
            const data = await getContactsByAccount({
                accountId: this.selectedAccountId,
                limitSize: this.pageSize,
                offsetSize: this.currentOffset,
                searchKey: this.searchKey || ''
            });

            this.contacts = data.map((contact, index) => ({
                ...contact,
                index: this.currentOffset + index + 1,
                contactUrl: `/lightning/r/Contact/${contact.Id}/view`
            }));
            this.sortData(this.sortBy, this.sortDirection);
        } catch (error) {
            this.showToast('Error', 'Error fetching contacts.', 'error');
            console.error('Error fetching contacts:', error);
            this.contacts = [];
        }
    }

    handleAccountChange(event) {
        this.selectedAccountId = event.detail.value;
        this.currentOffset = 0;
        this.fetchTotalContacts();
        this.fetchContacts();
    }

    handleSearch(event) {
        this.searchKey = event.target.value.trim();
        this.currentOffset = 0;
        this.fetchTotalContacts();
        this.fetchContacts();
    }

    handleSort(event) {
        const { fieldName } = event.detail;
        this.sortDirection = this.sortBy === fieldName && this.sortDirection === 'asc' ? 'desc' : 'asc';
        this.sortBy = fieldName;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(field, direction) {
        if (!field) return;

        let sortedData = [...this.contacts];

        sortedData.sort((a, b) => {
            let valueA = a[field] ? a[field].toLowerCase() : '';
            let valueB = b[field] ? b[field].toLowerCase() : '';

            return direction === 'asc' ? valueA.localeCompare(valueB) : valueB.localeCompare(valueA);
        });

        this.contacts = sortedData;
    }

    handleNext() {
        if (!this.isNextDisabled) {
            this.currentOffset += this.pageSize;
            this.fetchContacts();
        }
    }

    handlePrevious() {
        if (!this.isPreviousDisabled) {
            this.currentOffset -= this.pageSize;
            this.fetchContacts();
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'edit') {
            this.selectedContactId = row.Id;
            this.isModalOpen = true;
        }
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleSuccess(event) {
        this.isModalOpen = false;
        const updatedFields = event.detail.fields;
            
        if (!updatedFields) {
            console.error('Error: No fields found in event.detail.');
            return;
        }
            
        this.showToast('Success', 'Contact updated successfully!', 'success');
            
            // fetch latest data
            this.fetchContacts();
    }
            



    /*
    *********************************************************
    @Method Name    : showToast
    @description    : Displays a toast message.
    @param          : title - Title of the message
                      message - Message content
                      variant - Type of message (success, error, warning, info)
    @return         : void
    ********************************************************
    */

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}