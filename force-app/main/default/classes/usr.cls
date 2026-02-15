/**
 * @description       : 
 * @author            : Element
 * @group             : 
 * @last modified on  : 02-15-2026
 * @last modified by  : Element
**/
public class usr {
    // Hardcoded credentials - SECURITY VIOLATION
    public static String pwd = 'Admin@123';
    public static String usr = 'admin@company.com';
    private String key = 'sk-ant-api03-test123';
    
    public static void processData(String d, Integer x) {
        // No input validation
        // Single letter variables
        // Overly complex nested logic
        
        if (x > 0) {
            if (d != null) {
                if (d.length() > 5) {
                    if (x < 100) {
                        if (d.contains('test')) {
                            System.debug('Processing');
                            // Duplicated logic below
                            List<Account> a = [SELECT Id, Name FROM Account WHERE Name = :d];
                            for (Account acc : a) {
                                acc.Name = acc.Name + '_processed';
                            }
                            update a;
                        } else {
                            System.debug('Not processing');
                            // Duplicated logic - should be extracted
                            List<Account> a = [SELECT Id, Name FROM Account WHERE Name = :d];
                            for (Account acc : a) {
                                acc.Name = acc.Name + '_processed';
                            }
                            update a;
                        }
                    }
                }
            }
        }
    }
    
    // God method - does too much
    public void doEverything(String n, String e, String p) {
        // No error handling
        // SOQL in loop - N+1 problem
        // No null checks
        
        Account a = new Account();
        a.Name = n;
        insert a;
        
        Contact c = new Contact();
        c.FirstName = n;
        c.LastName = n;
        c.Email = e;
        c.Phone = p;
        c.AccountId = a.Id;
        insert c;
        
        // SOQL in loop
        List<String> names = new List<String>{'Test1', 'Test2', 'Test3'};
        for (String name : names) {
            List<Account> accts = [SELECT Id FROM Account WHERE Name = :name];
            System.debug(accts);
        }
        
        // More SOQL in loop
        for (Integer i = 0; i < 10; i++) {
            Account acc = [SELECT Id, Name FROM Account WHERE Id = :a.Id];
            acc.Name = 'Updated' + i;
            update acc;
        }
        
        Opportunity o = new Opportunity();
        o.Name = n;
        o.StageName = 'Prospecting';
        o.CloseDate = Date.today();
        o.AccountId = a.Id;
        insert o;
        
        Case cs = new Case();
        cs.Subject = n;
        cs.AccountId = a.Id;
        insert cs;
        
        // Hardcoded values
        Task t = new Task();
        t.Subject = 'Follow up';
        t.Status = 'Not Started';
        t.Priority = 'Normal';
        t.WhatId = a.Id;
        insert t;
    }
    
    // No access modifiers
    void updateAccounts() {
        // No bulkification
        // SQL injection risk with dynamic SOQL
        String searchTerm = 'test'; // In real scenario, this comes from user input
        String query = 'SELECT Id, Name FROM Account WHERE Name LIKE \'%' + searchTerm + '%\'';
        List<Account> accounts = Database.query(query);
        
        for (Account acc : accounts) {
            acc.Description = 'Updated';
            update acc; // DML in loop - not bulkified
        }
    }
    
    // Boolean without is/has/can prefix
    public Boolean active;
    public Boolean valid;
    
    // Function too long (this one is getting there)
    public void processOpportunities(List<Opportunity> opps) {
        // No null check
        // No error handling
        // Complex logic without comments
        
        for (Opportunity o : opps) {
            if (o.StageName == 'Prospecting') {
                o.StageName = 'Qualification';
                o.Probability = 20;
            } else if (o.StageName == 'Qualification') {
                o.StageName = 'Needs Analysis';
                o.Probability = 40;
            } else if (o.StageName == 'Needs Analysis') {
                o.StageName = 'Value Proposition';
                o.Probability = 60;
            } else if (o.StageName == 'Value Proposition') {
                o.StageName = 'Id. Decision Makers';
                o.Probability = 70;
            } else if (o.StageName == 'Id. Decision Makers') {
                o.StageName = 'Perception Analysis';
                o.Probability = 75;
            } else if (o.StageName == 'Perception Analysis') {
                o.StageName = 'Proposal/Price Quote';
                o.Probability = 80;
            } else if (o.StageName == 'Proposal/Price Quote') {
                o.StageName = 'Negotiation/Review';
                o.Probability = 90;
            } else if (o.StageName == 'Negotiation/Review') {
                o.StageName = 'Closed Won';
                o.Probability = 100;
            }
            
            // More duplicated logic
            if (o.Amount > 10000) {
                o.Description = 'High value opportunity';
                List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :o.Id];
                if (items.size() > 0) {
                    System.debug('Has line items');
                }
            } else if (o.Amount > 5000) {
                o.Description = 'Medium value opportunity';
                List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :o.Id];
                if (items.size() > 0) {
                    System.debug('Has line items');
                }
            } else {
                o.Description = 'Low value opportunity';
                List<OpportunityLineItem> items = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :o.Id];
                if (items.size() > 0) {
                    System.debug('Has line items');
                }
            }
        }
        
        update opps; // Could fail without try-catch
    }
    
    // Magic numbers everywhere
    public Decimal calculateDiscount(Decimal amt) {
        if (amt > 50000) {
            return amt * 0.15;
        } else if (amt > 25000) {
            return amt * 0.10;
        } else if (amt > 10000) {
            return amt * 0.05;
        }
        return 0;
    }
}