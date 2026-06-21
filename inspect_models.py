import tflite

def inspect_model(model_path):
    print(f"\n================ Inspecting {model_path} ================")
    try:
        with open(model_path, "rb") as f:
            buf = f.read()
            model = tflite.Model.GetRootAsModel(buf, 0)
        
        subgraph = model.Subgraphs(0)
        
        # Inputs
        print("Inputs:")
        for i in range(subgraph.InputsLength()):
            input_idx = subgraph.Inputs(i)
            tensor = subgraph.Tensors(input_idx)
            name = tensor.Name().decode('utf-8')
            shape = [tensor.Shape(j) for j in range(tensor.ShapeLength())]
            dtype = tensor.Type()
            
            # DataType mapping: 0 = FLOAT32, 1 = INT32, 2 = UINT8, 3 = INT64, 4 = STRING, 9 = INT8
            dtype_name = {
                0: "FLOAT32",
                1: "INT32",
                2: "UINT8",
                3: "INT64",
                4: "STRING",
                9: "INT8"
            }.get(dtype, f"UNKNOWN ({dtype})")
            
            print(f"  Input {i}: '{name}', Shape: {shape}, Type: {dtype_name}")
            
        # Outputs
        print("\nOutputs:")
        for i in range(subgraph.OutputsLength()):
            output_idx = subgraph.Outputs(i)
            tensor = subgraph.Tensors(output_idx)
            name = tensor.Name().decode('utf-8')
            shape = [tensor.Shape(j) for j in range(tensor.ShapeLength())]
            dtype = tensor.Type()
            dtype_name = {
                0: "FLOAT32",
                1: "INT32",
                2: "UINT8",
                3: "INT64",
                4: "STRING",
                9: "INT8"
            }.get(dtype, f"UNKNOWN ({dtype})")
            
            print(f"  Output {i}: '{name}', Shape: {shape}, Type: {dtype_name}")
            
    except Exception as e:
        print(f"Error inspecting model: {e}")

if __name__ == "__main__":
    inspect_model("assets/gender_model.tflite")
    inspect_model("assets/age_model.tflite")
