package randori.async {
import guice.GuiceModule;
import guice.InjectionClassBuilder;

/**
 * Created with IntelliJ IDEA.
 * User: mlabriola
 * Date: 5/28/13
 * Time: 10:44 AM
 * To change this template use File | Settings | File Templates.
 */
public class AsyncClassBuilder {
	private var classBuilder:InjectionClassBuilder;

	public function buildContextByName( className:String ):Promise {
		var p:Promise = new Promise();

		var module:GuiceModule = classBuilder.buildContextByName(className ) as GuiceModule;

		p.resolve( module );

		return p;
	}

	public function buildDependencyByName( className:String ):Promise {
		var p:Promise = new Promise();

		var dep:* = classBuilder.buildDependencyByName(className );

		p.resolve( dep );

		return p;
	}

	public function buildDependency( dependency:Class ):* {
		var dep:* = classBuilder.buildDependency( dependency );
		return dep;
	}

	public function AsyncClassBuilder( classBuilder:InjectionClassBuilder) {
		this.classBuilder = classBuilder;
	}
}
}