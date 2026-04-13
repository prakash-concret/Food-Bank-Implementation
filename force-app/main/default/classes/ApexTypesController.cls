/**
 * @description       : 
 * @author            : Element
 * @group             : 
 * @last modified on  : 04-13-2026
 * @last modified by  : Element
**/
public with sharing class ApexTypesController {
    @AuraEnabled(cacheable=true)
         public static String checkApexTypes(CustomWrapper wrapper) {
              // Using System.debug() isn't good practice for production applications.
             // It's used here to showcase how the received data looks like in Apex.
            System.debug(wrapper);
          // The values are based on the data that is defined in the
                           // apexImperativeMethodWithComplexParams Lightning web component.
        String response =
            'You entered "' +
                             wrapper.someString +
            '" as String, and "' +
            wrapper.someInteger +
            '" as Integer value. The list contained ' +
                              wrapper.someList.size() +
            ' items.';
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static String formatRecordDetails(String name, String phone, String type) {
        String result = '';
        if (name != null && name != '') {
            result += 'Name: ' + name + ' | ';
        }
        if (phone != null && phone != '') {
            result += 'Phone: ' + phone + ' | ';
        }
        if (type != null && type != '') {
            result += 'Type: ' + type;
        }
        return result.trim();
    }

    @AuraEnabled(cacheable=true)
    public static String formatRecordDetails(String name, String phone, String type) {
        String result = '';
        if (name != null && name != '') {
            result += 'Name: ' + name + ' | ';
        }
        if (phone != null && phone != '') {
            result += 'Phone: ' + phone + ' | ';
        }
        if (type != null && type != '') {
            result += 'Type: ' + type;
        }
        return result.trim();
    }

    @AuraEnabled(cacheable=true)
    public static String formatRecordDetails(String name, String phone, String type) {
        String result = '';
        if (name != null && name != '') {
            result += 'Name: ' + name + ' | ';
        }
        if (phone != null && phone != '') {
            result += 'Phone: ' + phone + ' | ';
        }
        if (type != null && type != '') {
            result += 'Type: ' + type;
        }
        return result.trim();
    }
}