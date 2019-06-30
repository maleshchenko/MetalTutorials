class BufferProvider: NSObject {
    let inflightBuffersCount: Int
    private var uniformsBuffers: [MTLBuffer]
    private var avaliableBufferIndex: Int = 0
    
    var avaliableResourcesSemaphore: DispatchSemaphore
    
    init(device:MTLDevice, inflightBuffersCount: Int, sizeOfUniformsBuffer: Int) {
        
        self.inflightBuffersCount = inflightBuffersCount
        uniformsBuffers = [MTLBuffer]()
        
        for _ in 0...inflightBuffersCount - 1 {
            let uniformsBuffer = (device.makeBuffer(length: sizeOfUniformsBuffer, options: []))!
            uniformsBuffers.append(uniformsBuffer)
        }
        
        avaliableResourcesSemaphore = DispatchSemaphore(value: inflightBuffersCount)
    }
    
    func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
        
        let buffer = uniformsBuffers[avaliableBufferIndex]
        let bufferPointer = buffer.contents()
        
        memcpy(bufferPointer, modelViewMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(), projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        
        avaliableBufferIndex += 1
        if avaliableBufferIndex == inflightBuffersCount{
            avaliableBufferIndex = 0
        }
        
        return buffer
    }
    
    deinit {
        for _ in 0...self.inflightBuffersCount {
            self.avaliableResourcesSemaphore.signal()
        }
    }
}
