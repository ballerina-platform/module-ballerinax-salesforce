/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

package org.ballerinalang.sf.plugin;

import io.ballerina.compiler.api.symbols.ModuleSymbol;
import io.ballerina.compiler.api.symbols.ServiceDeclarationSymbol;
import io.ballerina.compiler.api.symbols.Symbol;
import io.ballerina.compiler.api.symbols.TypeDescKind;
import io.ballerina.compiler.api.symbols.TypeReferenceTypeSymbol;
import io.ballerina.compiler.api.symbols.TypeSymbol;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.projects.plugins.AnalysisTask;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.List;
import java.util.Optional;

import static org.ballerinalang.sf.plugin.Constants.BALLERINAX;
import static org.ballerinalang.sf.plugin.Constants.REMOTE_KEYWORD;
import static org.ballerinalang.sf.plugin.Constants.SFDC;

/**
 * Semantic analyzer with {@inheritDoc AnalysisTask<?>} for Ballerina sfdc listener.
 */
public class ServiceSemanticAnalyzer implements AnalysisTask<SyntaxNodeAnalysisContext> {
    @Override
    public void perform(SyntaxNodeAnalysisContext syntaxNodeAnalysisContext) {
        ServiceDeclarationNode serviceDeclarationNode = (ServiceDeclarationNode) syntaxNodeAnalysisContext.node();
        NodeList<Node> members = serviceDeclarationNode.members();
        Optional<Symbol> serviceSymOptional = syntaxNodeAnalysisContext.semanticModel().symbol(serviceDeclarationNode);
        if (serviceSymOptional.isPresent()) {
            List<TypeSymbol> listenerTypes = ((ServiceDeclarationSymbol) serviceSymOptional.get()).listenerTypes();
            if (listenerTypes.stream().noneMatch(this::isListenerBelongsToSfdcModule)) {
                return;
            }
        }
        SfdcResourceValidator.extractFunctionAnnotationAndValidate(syntaxNodeAnalysisContext, serviceDeclarationNode);
        for (Node member : members) {
            if (member.kind() == SyntaxKind.OBJECT_METHOD_DEFINITION) {
                FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) member;
                SfdcResourceValidator.validateResource(syntaxNodeAnalysisContext, functionDefinitionNode);
                if (functionDefinitionNode.qualifierList().stream().anyMatch(token ->
                        token.text().equals(REMOTE_KEYWORD))) {
                    continue;
                }
            }
            if (member.kind() == SyntaxKind.RESOURCE_ACCESSOR_DEFINITION) {
                FunctionDefinitionNode functionDefinitionNode = (FunctionDefinitionNode) member;
                DiagnosticInfo diagnosticInfo = new DiagnosticInfo(SfdcDiagnosticCodes.SFDC_107.getCode(),
                        SfdcDiagnosticCodes.SFDC_107.getMessage(),
                        SfdcDiagnosticCodes.SFDC_107.getSeverity());
                syntaxNodeAnalysisContext.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo,
                        functionDefinitionNode.location()));
            }
        }
    }

    /**
     * Validate if the listener belongs to sfdc module
     * @param listenerType  {@link TypeSymbol} representing the type of the resource
     */
    private boolean isListenerBelongsToSfdcModule(TypeSymbol listenerType) {
        if (listenerType.typeKind() == TypeDescKind.TYPE_REFERENCE) {
            return isSfdcModule(((TypeReferenceTypeSymbol) listenerType).typeDescriptor().getModule().orElseThrow());
        }
        return false;
    }

    /**
     * Validate if the module name is sfdc
     * @param moduleSymbol  {@link ModuleSymbol} representing the module symbol
     */
    private boolean isSfdcModule(ModuleSymbol moduleSymbol) {
        return SFDC.equals(moduleSymbol.getName().orElseThrow()) && BALLERINAX.equals(moduleSymbol.id().orgName());
    }
}
