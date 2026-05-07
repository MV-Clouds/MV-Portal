@RestResource(urlMapping='/employee/*')
global with sharing class EmployeeRestService {

    /*
     * CREATE EMPLOYEE
     */
    @HttpPost
    global static String createEmployee() {

        RestResponse res = RestContext.response;

        try {

            String jsonString = RestContext.request.requestBody.toString();
             System.debug('JSON : ' + jsonString);

            System.debug('Webhook Payload: ' + jsonString);

            jsonString = jsonString.replaceAll(',[\\s\\n]*(})', '$1');


            Map<String, Object> webhookData =
                (Map<String, Object>) JSON.deserializeUntyped(jsonString);

            Employee__c emp = new Employee__c();

            Map<String, Schema.SObjectField> fieldMap =
                Schema.SObjectType.Employee__c.fields.getMap();

            for(String fieldName : webhookData.keySet()) {

                if(fieldMap.containsKey(fieldName)) {

                    Object fieldValue = webhookData.get(fieldName);

                    Schema.DescribeFieldResult fieldDescribe =
                        fieldMap.get(fieldName).getDescribe();

                    Schema.DisplayType fieldType = fieldDescribe.getType();

                    if(fieldValue != null) {

                        if(fieldType == Schema.DisplayType.Date) {

                            emp.put(
                                fieldName,
                                Date.valueOf(String.valueOf(fieldValue))
                            );

                        } else if(fieldType == Schema.DisplayType.DateTime) {

                            emp.put(
                                fieldName,
                                Datetime.valueOf(String.valueOf(fieldValue))
                            );

                        } else if(fieldType == Schema.DisplayType.Currency ||
                                  fieldType == Schema.DisplayType.Double ||
                                  fieldType == Schema.DisplayType.Percent) {

                            emp.put(
                                fieldName,
                                Decimal.valueOf(String.valueOf(fieldValue))
                            );

                        } else if(fieldType == Schema.DisplayType.Integer) {

                            emp.put(
                                fieldName,
                                Integer.valueOf(String.valueOf(fieldValue))
                            );

                        } else if(fieldType == Schema.DisplayType.Boolean) {

                            emp.put(
                                fieldName,
                                Boolean.valueOf(String.valueOf(fieldValue))
                            );

                        } else {

                            emp.put(fieldName, fieldValue);
                        }
                    }
                }
            }

            insert emp;

            res.statusCode = 201;

            return JSON.serialize(new Map<String, Object>{
                'success' => true,
                'message' => 'Employee record created successfully',
                'recordId' => emp.Id
            });

        } catch (Exception e) {

            res.statusCode = 400;
            System.debug('Error : ' + e.getMessage());

            return JSON.serialize(new Map<String, Object>{
                'success' => false,
                'message' => e.getMessage()
            });
        }
    }

    /*
     * GET ALL EMPLOYEE__c FIELDS
     */
    @HttpGet
    global static String getEmployeeFields() {

        RestResponse res = RestContext.response;

        try {

            Map<String, Schema.SObjectField> fieldMap =
                Schema.SObjectType.Employee__c.fields.getMap();

            List<Map<String, String>> fieldsList = new List<Map<String, String>>();

            for(String fieldName : fieldMap.keySet()) {

                Schema.DescribeFieldResult fieldDescribe =
                    fieldMap.get(fieldName).getDescribe();

                Map<String, String> fieldDetails = new Map<String, String>();

                fieldDetails.put('apiName', fieldName);
                fieldDetails.put('label', fieldDescribe.getLabel());
                fieldDetails.put('type', String.valueOf(fieldDescribe.getType()));

                fieldsList.add(fieldDetails);
            }

            res.statusCode = 200;

            return JSON.serialize(new Map<String, Object>{
                'success' => true,
                'fields' => fieldsList
            });

        } catch (Exception e) {

            res.statusCode = 400;

            return JSON.serialize(new Map<String, Object>{
                'success' => false,
                'message' => e.getMessage()
            });
        }
    }
}