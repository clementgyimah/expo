
/**
 A protocol that must be implemented to be a part of module's definition and the module definition itself.
 */
public protocol AnyDefinition {}

/**
 The definition of the module. It is used to define some parameters
 of the module and what it exports to the JavaScript world.
 See `ModuleDefinitionBuilder` for more details on how to create it.
 */
public class ModuleDefinition: AnyDefinition {
  var type: AnyModule.Type?

  let definedName: String?
  let methods: [String : AnyMethod]
  let constants: [String : Any?]
  let eventListeners: [EventListener]
  let viewManager: ViewManagerDefinition?

  /**
   Initializer that is called by the `ModuleDefinitionBuilder` results builder.
   */
  init(definitions: [AnyDefinition]) {
    self.definedName = definitions
      .compactMap { $0 as? ModuleNameDefinition }
      .last?
      .name

    self.methods = definitions
      .compactMap { $0 as? AnyMethod }
      .reduce(into: [String : AnyMethod]()) { dict, method in
        dict[method.name] = method
      }

    self.constants = definitions
      .compactMap { $0 as? ConstantsDefinition }
      .reduce(into: [String : Any?]()) { dict, definition in
        dict.merge(definition.constants) { $1 }
      }

    self.eventListeners = definitions.compactMap { $0 as? EventListener }

    self.viewManager = definitions
      .compactMap { $0 as? ViewManagerDefinition }
      .last
  }

  /**
   Defining the module name is optional, this property provides a fallback to the type name.
   */
  var name: String {
    return self.definedName ?? String(describing: type)
  }

  /**
   Sets the module type that the definition is associated with. We can't pass this in the initializer
   as it's called by the results builder that doesn't have access to the type.
   */
  func withType(_ type: AnyModule.Type) -> Self {
    self.type = type
    return self
  }
}

/**
 Module's name definition. Returned by `name()` in module's definition.
 */
internal struct ModuleNameDefinition: AnyDefinition {
  let name: String
}

/**
 A definition for module's constants. Returned by `constants(() -> SomeType)` in module's definition.
 */
internal struct ConstantsDefinition: AnyDefinition {
  let constants: [String : Any?]
}
