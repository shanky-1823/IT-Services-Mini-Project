trigger ProjectTrigger on Project__c (after insert, after update) {
    
    if(Trigger.isInsert){
        //Calling create project assignment method
        ProjectTriggerHandler.createProjectAssignment(Trigger.new);
    }
    if(trigger.isUpdate){
        //Calling send email method
        ProjectTriggerHandler.sendEmail(Trigger.new);
    }
    
}