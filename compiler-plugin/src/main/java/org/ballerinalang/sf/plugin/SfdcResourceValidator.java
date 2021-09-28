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

import io.ballerina.compiler.syntax.tree.AnnotationNode;
import io.ballerina.compiler.syntax.tree.FunctionDefinitionNode;
import io.ballerina.compiler.syntax.tree.FunctionSignatureNode;
import io.ballerina.compiler.syntax.tree.IdentifierToken;
import io.ballerina.compiler.syntax.tree.MetadataNode;
import io.ballerina.compiler.syntax.tree.Node;
import io.ballerina.compiler.syntax.tree.NodeList;
import io.ballerina.compiler.syntax.tree.ParameterNode;
import io.ballerina.compiler.syntax.tree.RequiredParameterNode;
import io.ballerina.compiler.syntax.tree.SeparatedNodeList;
import io.ballerina.compiler.syntax.tree.ServiceDeclarationNode;
import io.ballerina.compiler.syntax.tree.SyntaxKind;
import io.ballerina.compiler.syntax.tree.Token;
import io.ballerina.projects.plugins.SyntaxNodeAnalysisContext;
import io.ballerina.tools.diagnostics.DiagnosticFactory;
import io.ballerina.tools.diagnostics.DiagnosticInfo;

import java.util.Optional;

import static org.ballerinalang.sf.plugin.Constants.EVENT_DATA_TYPE;
import static org.ballerinalang.sf.plugin.Constants.ON_CREATE;
import static org.ballerinalang.sf.plugin.Constants.ON_DELETE;
import static org.ballerinalang.sf.plugin.Constants.ON_RESTORE;
import static org.ballerinalang.sf.plugin.Constants.ON_UPDATE;
import static org.ballerinalang.sf.plugin.Constants.SERVICE_CONFIG_ANNOTATION;

/**
 * Validates a ballerina sfdc resource.
 */
public class SfdcResourceValidator {
    /**
     * Validate each resource in SFDC listener
     * @param ctx    {@link SyntaxNodeAnalysisContext}
     * @param member {@link FunctionDefinitionNode}
     */
    static void validateResource(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        extractRemoteMethodNameAndValidate(ctx, member);
        extractResourceParametersAndValidate(ctx, member);
        extractQualifierListAndValidate(ctx, member);
    }

    /**
     * Validate annotation in SFDC listener
     * @param ctx    {@link SyntaxNodeAnalysisContext}
     * @param member {@link FunctionDefinitionNode}
     */
    static void extractFunctionAnnotationAndValidate(SyntaxNodeAnalysisContext ctx, ServiceDeclarationNode member) {
        Optional<MetadataNode> metadataNodeOptional = member.metadata();
        if (metadataNodeOptional.isEmpty()) {
            updateDiagnostic(ctx, member, "empty", SfdcDiagnosticCodes.SFDC_101);
        } else {
            MetadataNode metadataNode = metadataNodeOptional.orElseThrow();
            NodeList<AnnotationNode> annotations = metadataNode.annotations();
            for (AnnotationNode annotation : annotations) {
                Node annotationReference = annotation.annotReference();
                String annotationName = annotationReference.toString();
                if (annotationReference.kind() == SyntaxKind.QUALIFIED_NAME_REFERENCE) {
                    String[] strings = annotationName.split(":");
                    if (SERVICE_CONFIG_ANNOTATION.equals(strings[strings.length - 1].trim())) {
                        continue;
                    }
                }
                updateDiagnostic(ctx, metadataNode, annotationName, SfdcDiagnosticCodes.SFDC_101);
            }
        }
    }

    /**
     * Validate qualifier in SFDC listener
     * @param ctx    {@link SyntaxNodeAnalysisContext}
     * @param member {@link FunctionDefinitionNode}
     */
    private static void extractQualifierListAndValidate(SyntaxNodeAnalysisContext ctx, FunctionDefinitionNode member) {
        NodeList<Token> tokens = member.qualifierList();
        if (tokens.isEmpty()) {
            updateDiagnostic(ctx, member, "remote", SfdcDiagnosticCodes.SFDC_106);
        }
    }

    /**
     * Validate remote method name in SFDC listener
     * @param ctx    {@link SyntaxNodeAnalysisContext}
     * @param member {@link FunctionDefinitionNode}
     */
    private static void extractRemoteMethodNameAndValidate(SyntaxNodeAnalysisContext ctx,
                                                           FunctionDefinitionNode member) {
        IdentifierToken functionNameToken = member.functionName();
        String functionName = functionNameToken.toString().trim();
        if (!(functionName.equals(ON_UPDATE) || functionName.equals(ON_CREATE) || functionName.equals(ON_DELETE) ||
                functionName.equals(ON_RESTORE))) {
            updateDiagnostic(ctx, functionNameToken, functionName, SfdcDiagnosticCodes.SFDC_102);
        }
    }

    /**
     * Validate service parameters in SFDC listener
     * @param ctx    {@link SyntaxNodeAnalysisContext}
     * @param member {@link FunctionDefinitionNode}
     */
    private static void extractResourceParametersAndValidate(SyntaxNodeAnalysisContext ctx,
                                                             FunctionDefinitionNode member) {
        FunctionSignatureNode signatureNode = member.functionSignature();
        SeparatedNodeList<ParameterNode> parameterList = signatureNode.parameters();
        if (parameterList.isEmpty()) {
            updateDiagnostic(ctx, signatureNode, "empty", SfdcDiagnosticCodes.SFDC_103);
        } else if (parameterList.size() > 1) {
            updateDiagnostic(ctx, signatureNode, "more than one", SfdcDiagnosticCodes.SFDC_104);
        } else {
            ParameterNode node = parameterList.get(0);
            Node typeNameReference = ((RequiredParameterNode) node).typeName();
            String typeName = typeNameReference.toString();
            String[] strings = typeName.split(":");
            if (!(EVENT_DATA_TYPE.equals(strings[strings.length - 1].trim()))) {
                updateDiagnostic(ctx, signatureNode, typeName, SfdcDiagnosticCodes.SFDC_105);
            }
        }
    }

    /**
     * Populate the diagnostic with necessary data
     * @param ctx                   {@link SyntaxNodeAnalysisContext}
     * @param node                  {@link Node}
     * @param resourceName          {@link String} representing the name of the resource
     * @param sfdcDiagnosticCodes   {@link SfdcDiagnosticCodes}
     */
    private static void updateDiagnostic(SyntaxNodeAnalysisContext ctx, Node node, String resourceName,
                                         SfdcDiagnosticCodes sfdcDiagnosticCodes) {
        DiagnosticInfo diagnosticInfo = getDiagnosticInfo(sfdcDiagnosticCodes, resourceName);
        ctx.reportDiagnostic(DiagnosticFactory.createDiagnostic(diagnosticInfo, node.location()));
    }

    /**
     * Get diagnostic info
     * @param sfdcDiagnosticCodes   {@link SfdcDiagnosticCodes}
     * @param args                  {@link Object} representing the necessary information for diagnostic message
     */
    private static DiagnosticInfo getDiagnosticInfo(SfdcDiagnosticCodes sfdcDiagnosticCodes, Object... args) {
        return new DiagnosticInfo(sfdcDiagnosticCodes.getCode(), String.format(sfdcDiagnosticCodes.getMessage(), args),
                sfdcDiagnosticCodes.getSeverity());
    }
}
