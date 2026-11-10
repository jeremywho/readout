import Foundation
import ReadoutCore
import ReadoutSystem

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.contains("--sensors") {
    for sensor in SMCSampler().allTemperatureSensors().sorted(by: { $0.key < $1.key }) {
        print("\(sensor.key)\t\(String(format: "%.2f", sensor.celsius))")
    }
    exit(0)
}

if arguments.contains("--check") {
    let result = await SelfTest.run()
    print(result.report)
    let clusterTypes = CPUSampler.readClusterTypes()
    let groups = CoreTopology.groups(
        clusterTypes: clusterTypes, levels: CPUSampler.readLevels(), coreCount: ProcessInfo.processInfo.processorCount)
    print("cores: " + String(clusterTypes))
    print("core groups: " + groups.map { "\($0.name ?? "unnamed") x\($0.cores.count)" }.joined(separator: ", "))
    exit(result.passed ? 0 : 1)
}

let limit =
    arguments.firstIndex(of: "--seconds").flatMap { index in
        arguments.indices.contains(index + 1) ? Int(arguments[index + 1]) : nil
    } ?? Int.max

let engine = SamplingEngine()
for _ in 0..<limit {
    print(ProbeLine.render(await engine.tick()))
    fflush(stdout)
    try await Task.sleep(for: .seconds(1))
}
