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
import guice.ChildInjector;
import guice.GuiceJs;
import guice.GuiceModule;

import randori.async.AsyncClassBuilder;
import randori.async.Promise;
import randori.behaviors.AbstractBehavior;
import randori.webkit.html.HTMLElement;
import randori.webkit.page.Window;

public class AsyncExtensionResolver {

	private var classBuilder:AsyncClassBuilder;

	private function resolveContext( element:HTMLElement, elementDescriptor:ElementDescriptor, resolved:ElementResolution ):Promise {
		var cClassBuilder:AsyncClassBuilder = this.classBuilder;

		if (elementDescriptor.context != null) {
			var contextPromise:Promise = classBuilder.buildContextByName(elementDescriptor.context);
			var onGoingPromise:Promise = contextPromise.then( function( context:GuiceModule ):Promise {

				//Add the newly resolved context to the resolution
				resolved.context = context;

				var injector:ChildInjector = cClassBuilder.buildDependency(ChildInjector) as ChildInjector;
				//This is a problem, refactor me
				var guiceJs:GuiceJs = new GuiceJs( null );
				guiceJs.configureInjector(injector, resolved.context );

				//Setup a new AsyncExtensionResolver
				var extensionResolver:AsyncExtensionResolver = injector.getInstance(AsyncExtensionResolver) as AsyncExtensionResolver;
				return extensionResolver.resolveBehavior( element, elementDescriptor, resolved );
			})

			return onGoingPromise;
		} else {
			return resolveBehavior( element, elementDescriptor, resolved );
		}
	}

	private function resolveBehavior( element:HTMLElement, elementDescriptor:ElementDescriptor, resolved:ElementResolution ):Promise {
		if (elementDescriptor.behavior != null) {
			var extensionResolver:AsyncExtensionResolver = this;
			var behaviorPromise:Promise = classBuilder.buildDependencyByName(elementDescriptor.behavior);
			var onGoingPromise:Promise = behaviorPromise.then( function( behavior:AbstractBehavior ):Promise {
				resolved.behavior = behavior;
				return extensionResolver.resolveFragment( element, elementDescriptor, resolved );
			})
			return onGoingPromise;
		} else {
			return resolveFragment( element, elementDescriptor, resolved );
		}
	}

	private function resolveFragment( element:HTMLElement, elementDescriptor:ElementDescriptor, resolved:ElementResolution ):Promise {
		if (elementDescriptor.fragment != null) {
			//var fragmentPromise:Promise = classBuilder.buildDependencyByName(elementDescriptor.behavior);

			//get async fragment loading
			var p1:Promise = new Promise();
			p1.resolve(resolved)
			return p1;
		}

		var p:Promise = new Promise();
		p.resolve(resolved)
		return p;
	}

	public function resolveExtension( element:HTMLElement, elementDescriptor:ElementDescriptor ):Promise {

		Window.console.log("Creating Promise(s) to resolveExtensions");
		return resolveContext( element, elementDescriptor, new ElementResolution() );
	}

	public function AsyncExtensionResolver( classBuilder:AsyncClassBuilder ) {
		this.classBuilder = classBuilder;
	}
}
}