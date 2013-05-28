/***
 * Copyright 2013 LTN Consulting, Inc. /dba Digital Primates®
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 *
 * @author Michael Labriola <labriola@digitalprimates.net>
 */
package randori.dom {
import randori.async.Promise;
import randori.webkit.dom.Node;
import randori.webkit.html.HTMLElement;
import randori.webkit.page.Window;

public class DomSubtreeResolver {
	private var extensionResolver:AsyncExtensionResolver;
	private var elementDescriptorFactory:ElementDescriptorFactory;

	private function getElementDescriptor( node:Node ):ElementDescriptor {
		if ( node.nodeType == Node.ELEMENT_NODE ) {
			var elementDescriptor:ElementDescriptor = elementDescriptorFactory.describeElement(node as HTMLElement, null );
			if ( elementDescriptor.context != null || elementDescriptor.behavior != null) {
				return elementDescriptor;
			}
		}
		return null;
	}

	public function resolveNode( node:Node ):Promise {
		if ( !node )
			return null;

		var that:DomSubtreeResolver = this;
		var subTreePromise:Promise;
		var siblingPromise:Promise;

		var descriptor:ElementDescriptor = getElementDescriptor( node );
		if ( descriptor ) {
			Window.console.log( "Interested in " + node.nodeName + " " + ( node as HTMLElement ).getAttribute( "id") );

			subTreePromise = extensionResolver.resolveExtension( node as HTMLElement, descriptor );

			//We need to finish recursing the subtree of this element
			//that starts synchronously but could become async again

			subTreePromise = subTreePromise.then( function( resolved:ElementResolution ):Promise {

				if ( resolved.behavior ) {
					var thiny:* = resolved.behavior;
					Window.console.log( "Applying " + thiny.constructor.className );

					//after we provide behavior to this element
					resolved.behavior.provideDecoratedElement(node as HTMLElement);
				}

				return that.resolveNode( node.firstChild );
			})
		} else {
			subTreePromise = resolveNode( node.firstChild );
		}

		siblingPromise = resolveNode( node.nextSibling );

		if ( subTreePromise && siblingPromise ) {
			//I think this could be functionally composed better
			return new Promise().all( subTreePromise, siblingPromise );
		} else if ( subTreePromise ) {
			return subTreePromise;
		} else if ( siblingPromise ) {
			return siblingPromise;
		}

		return null;
	}

	public function DomSubtreeResolver( extensionResolver:AsyncExtensionResolver, elementDescriptorFactory:ElementDescriptorFactory ) {
		this.extensionResolver = extensionResolver;
		this.elementDescriptorFactory = elementDescriptorFactory;
	}
}
}