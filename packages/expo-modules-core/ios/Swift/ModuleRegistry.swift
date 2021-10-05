
public class ModuleRegistry: Sequence {
  public typealias Element = ModuleHolder

  private var appContext: AppContext

  private var definitionsRegistry: [String: ModuleDefinition] = [:]

  private var registry: [String: ModuleHolder] = [:]

  init(appContext: AppContext) {
    self.appContext = appContext
  }

  /**
   Registers a module type.
   */
  public func register(moduleType: AnyModule.Type) {
    let definition = moduleType.definition().withType(moduleType)
    definitionsRegistry[definition.name] = definition
  }

  /**
   Registers modules exported by given modules provider.
   */
  public func register(fromProvider provider: ModulesProviderProtocol) {
    provider.getModuleClasses().forEach { moduleType in
      register(moduleType: moduleType)
    }
  }

  /**
   Unregisters given module from the registry.
   */
  public func unregister(module: AnyModule) {
    if let index = registry.firstIndex(where: { $1.module === module }) {
      registry.remove(at: index)
    }
  }

  public func has(moduleWithName moduleName: String) -> Bool {
    return registry[moduleName] != nil
  }

  public func get(moduleHolderForName moduleName: String) -> ModuleHolder? {
    return registry[moduleName] ?? createInstance(moduleName)
  }

  public func get(moduleWithName moduleName: String) -> AnyModule? {
    return registry[moduleName]?.module
  }

  public func makeIterator() -> IndexingIterator<[ModuleHolder]> {
    return registry.map({ $1 }).makeIterator()
  }

  internal func post(event: EventName) {
    forEach { holder in
      holder.post(event: event)
    }
  }

  internal func post<PayloadType>(event: EventName, payload: PayloadType? = nil) {
    forEach { holder in
      holder.post(event: event, payload: payload)
    }
  }

  // MARK: privates

  private func createInstance(_ name: String) -> ModuleHolder? {
    if let definition = definitionsRegistry[name] {
      registry[name] = ModuleHolder(appContext: appContext, definition: definition)
    }
    return registry[name]
  }
}
