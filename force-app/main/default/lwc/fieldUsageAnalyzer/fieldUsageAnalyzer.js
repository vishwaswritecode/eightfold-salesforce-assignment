import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getObjects
    from '@salesforce/apex/FieldUsageController.getObjects';

import getFields
    from '@salesforce/apex/FieldUsageController.getFields';

import analyzeFieldUsage
    from '@salesforce/apex/FieldUsageController.analyzeFieldUsage';

export default class FieldUsageAnalyzer extends LightningElement {

    @track objectOptions = [];
    @track fieldOptions = [];
    @track selectedFields = [];
    @track analysisResults = [];

    selectedObject;
    isLoading = false;
    analysisExecuted = false;

    columns = [
        {
            label: 'Field',
            fieldName: 'fieldLabel',
            type: 'text'
        },
        {
            label: 'Field API Name',
            fieldName: 'fieldApiName',
            type: 'text'
        },
        {
            label: 'Metadata Type',
            fieldName: 'metadataType',
            type: 'text'
        },
        {
            label: 'Component Name',
            fieldName: 'componentName',
            type: 'text'
        },
        {
            label: 'Reference Type',
            fieldName: 'referenceType',
            type: 'text'
        }
    ];

    connectedCallback() {
        this.loadObjects();
    }

    async loadObjects() {
        this.isLoading = true;

        try {
            const result = await getObjects();

            this.objectOptions = result.map(item => ({
                label: `${item.label} (${item.apiName})`,
                value: item.apiName
            }));

        } catch (error) {
            this.showError(
                'Error loading Salesforce objects',
                error
            );
        } finally {
            this.isLoading = false;
        }
    }

    async handleObjectChange(event) {

        this.selectedObject = event.detail.value;

        // Reset previous state
        this.selectedFields = [];
        this.fieldOptions = [];
        this.analysisResults = [];
        this.analysisExecuted = false;

        await this.loadFields();
    }

    async loadFields() {

        if (!this.selectedObject) {
            return;
        }

        this.isLoading = true;

        try {

            const result = await getFields({
                objectApiName: this.selectedObject
            });

            this.fieldOptions = result.map(item => ({
                label: `${item.label} (${item.apiName})`,
                value: item.apiName
            }));

        } catch (error) {

            this.showError(
                'Error loading fields',
                error
            );

        } finally {

            this.isLoading = false;

        }
    }

    handleFieldChange(event) {

        this.selectedFields = event.detail.value;

        // Clear previous analysis if selection changes
        this.analysisResults = [];
        this.analysisExecuted = false;
    }

    async handleAnalyze() {

        if (
            !this.selectedObject ||
            !this.selectedFields ||
            this.selectedFields.length === 0
        ) {
            return;
        }

        this.isLoading = true;
        this.analysisExecuted = false;

        try {

            const result = await analyzeFieldUsage({
                objectApiName: this.selectedObject,
                fieldApiNames: this.selectedFields
            });

            this.analysisResults = (result || []).map(
                (item, index) => ({
                    ...item,
                    id:
                        `${item.fieldApiName}-${item.metadataType}-` +
                        `${item.componentName}-${index}`
                })
            );

            this.analysisExecuted = true;

            this.showToast(
                'Analysis Complete',
                `${this.analysisResults.length} metadata reference(s) found.`,
                'success'
            );

        } catch (error) {

            this.analysisResults = [];
            this.analysisExecuted = true;

            this.showError(
                'Error analyzing field usage',
                error
            );

        } finally {

            this.isLoading = false;

        }
    }

    get isAnalyzeDisabled() {
        return (
            this.isLoading ||
            !this.selectedObject ||
            !this.selectedFields ||
            this.selectedFields.length === 0
        );
    }

    get hasResults() {
        return (
            this.analysisExecuted &&
            this.analysisResults.length > 0
        );
    }

    get showNoResults() {
        return (
            this.analysisExecuted &&
            !this.isLoading &&
            this.analysisResults.length === 0
        );
    }

    showToast(title, message, variant) {

        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    showError(title, error) {

        let message = 'Unknown error';

        if (error?.body?.message) {
            message = error.body.message;
        } else if (error?.message) {
            message = error.message;
        }

        this.showToast(
            title,
            message,
            'error'
        );
    }
}