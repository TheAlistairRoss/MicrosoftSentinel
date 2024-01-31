

@description('Specifies the ID of the policy definition or policy set definition being assigned.')
param policyDefinitionID string

@description('Specifies the name of the policy assignment, can be used defined or an idempotent name as the defaultValue provides.')
param policyAssignmentName string = guid(policyDefinitionID, resourceGroup().name)

param policyParameters object = {Parameter1: 'value1', Parameter2: 'value2'}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: policyAssignmentName
  properties: {
    scope: resourceGroup().id
    policyDefinitionId: policyDefinitionID
    parameters: policyParameters
  }
}
