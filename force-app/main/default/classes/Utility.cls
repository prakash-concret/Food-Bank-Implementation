/**
 * @description       :
 * @author            : Element
 * @group             :
 * @last modified on  : 10-20-2025
 * @last modified by  : Element
 **/
public with sharing class Utility {
    @TestVisible
    private static Utility utilityObj;

    public static String namespace {
        get {
            if (namespace == null) {
                String withDotNotation = Utility.class.getName();
                if (withDotNotation.contains('.')) {
                    namespace = withDotNotation.substringBefore('.');
                } else {
                    namespace = '';
                }
            }
            return namespace;
        }
        set {
            namespace = value;
        }
    }

    public static String namespacePrefixWithDot {
        get {
            if (namespacePrefixWithDot == null) {
                if (String.isNotEmpty(namespace)) {
                    namespacePrefixWithDot = namespace + '.';
                } else {
                    namespacePrefixWithDot = '';
                }
            }
            return namespacePrefixWithDot;
        }
        set {
            namespacePrefixWithDot = value;
        }
    }

    public static String namespacePrefix {
        get {
            if (namespacePrefix == null) {
                if (String.isNotEmpty(namespace)) {
                    namespacePrefix = namespace + '__';
                } else {
                    namespacePrefix = '';
                }
            }
            return namespacePrefix;
        }
        set {
            namespacePrefix = value;
        }
    }
    /**
     * @description Get  the community base url value includes the path prefix and never ends with a / character
     * @author Element | 01-03-2025
     * @return String
     **/
    public static String currentCommunityBaseURL {
        get {
            if (String.isNotBlank(Site.getBaseRequestUrl())) {
                return Site.getBaseRequestUrl();
            }
            return Site.getBaseCustomUrl();
        }
        private set;
    }

    public static Utility getInstance() {
        if (utilityObj == null) {
            utilityObj = new Utility();
        }
        return utilityObj;
    }
}
