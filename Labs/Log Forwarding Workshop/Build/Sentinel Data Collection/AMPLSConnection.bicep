
param amplsResourceId string
param amplsScopedResourceIds array 

resource azureMonitorPrivateLinkScope 'microsoft.insights/privatelinkscopes@2021-07-01-preview' existing = {
  name: split(amplsResourceId,'/')[8]
}

resource amplsScopedResources 'microsoft.insights/privatelinkscopes/scopedresources@2021-07-01-preview' = [for scopedResourceId in amplsScopedResourceIds : {
  parent: azureMonitorPrivateLinkScope
  name: 'scoped-${split(scopedResourceId,'/')[8]}-${guid(scopedResourceId)}'
  properties: {
    linkedResourceId: scopedResourceId
  }
}
]
