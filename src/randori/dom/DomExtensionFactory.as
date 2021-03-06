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
import guice.GuiceJs;
import guice.IGuiceModule;
import guice.IInjector;
import guice.InjectionClassBuilder;
import guice.reflection.TypeDefinition;
import guice.reflection.TypeDefinitionFactory;

import randori.behaviors.AbstractBehavior;
import randori.content.ContentLoader;
import randori.jquery.JQueryStatic;
import randori.signal.SimpleSignal;
import randori.webkit.html.HTMLElement;

import robotlegs.flexo.command.ICommandMap;
import robotlegs.flexo.config.IConfig;
import robotlegs.flexo.context.DefaultContextModule;
import robotlegs.flexo.context.IContextInitialized;

public class DomExtensionFactory {
	private var contentLoader:ContentLoader;
	private var factory:TypeDefinitionFactory;
	private var externalBehaviorFactory:ExternalBehaviorFactory;

	public function buildBehavior( classBuilder:InjectionClassBuilder, element:HTMLElement, behaviorClassName:String):AbstractBehavior {
		var behavior:AbstractBehavior = null;

		var resolution:TypeDefinition = factory.getDefinitionForName( behaviorClassName );

		if ( resolution.builtIn ) {
			/** If we have a type which was not created via Randori, we send it out to get created. In this way
			 * we dont worry about injection data and we allow for any crazy creation mechanism the client can
			 * consider **/
			behavior = externalBehaviorFactory.createExternalBehavior( element, behaviorClassName, resolution.type );
		} else {
			behavior = classBuilder.buildClass( behaviorClassName ) as AbstractBehavior;
			behavior.provideDecoratedElement( element );
		}

		return behavior;
	}

	public function buildNewContent( element:HTMLElement, fragmentURL:String ):void {
		JQueryStatic.J( element ).append( contentLoader.synchronousFragmentLoad( fragmentURL ) );
	}

	public function buildChildClassBuilder( classBuilder:InjectionClassBuilder, element:HTMLElement, contextClassName:String ):InjectionClassBuilder {
		var module:IGuiceModule = classBuilder.buildContext( contextClassName ) as IGuiceModule;
		var injector:IInjector = classBuilder.buildClass( "guice.IInjector" ) as IInjector;

		//This is a problem, refactor me
		var guiceJs:GuiceJs = new GuiceJs( null );
		//Sets up the context to have the initialized and destoryed signals
		guiceJs.configureInjector( injector, new DefaultContextModule() );
		guiceJs.configureInjector( injector, module );

		var config:IConfig = module as IConfig;

		if ( config.configureCommands ) {
			//Get a new command map
			var map:ICommandMap = injector.getInstance( ICommandMap ) as ICommandMap;
			config.configureCommands( map );
		}

		//Let everyone know the context is initialized
		var signal:SimpleSignal = injector.getInstance( IContextInitialized );
		signal.dispatch();

		//Setup a new InjectionClassBuilder
		return injector.getInstance( InjectionClassBuilder ) as InjectionClassBuilder;
	}


	public function DomExtensionFactory( contentLoader:ContentLoader, factory:TypeDefinitionFactory, externalBehaviorFactory:ExternalBehaviorFactory ) {
		this.contentLoader = contentLoader;
		this.factory = factory;
		this.externalBehaviorFactory = externalBehaviorFactory;
	}
}
}
