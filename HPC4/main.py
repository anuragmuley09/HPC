import torch

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

x = torch.rand(3, 3).to(device)
y = torch.rand(3, 3).to(device)

print("Device:", device)
print(x + y)