import zarr

data_path = (
    "/capstor/store/cscs/swissai/a01/sadamov/ifs_2019-2020-0012-1440x721.zarr"
)
datav3_path = (
    "/capstor/store/cscs/swissai/a01/sadamov/ifs_2019-2020-0012-1440x721_zarrv3.zarr"
)

group_v2 = zarr.open(data_path)
store = zarr.storage.LocalStore(datav3_path)
group_v3 = zarr.create_group(store=store, overwrite=True, zarr_format=3)

# copy attrs
for key, value in group_v2.attrs.items():
    group_v3.attrs[key] = value

# copy arrays
shards_factor = 10
print(group_v2.info_complete())
vars_ = list(group_v2.keys())
nvars = len(vars_)
print("Arrays to copy:", vars_)

for i, (key, array) in enumerate(group_v2.arrays()):
    print(
        f"Copying array [{i + 1}/{nvars}] : {key}, shape: {array.shape}, size: {array.nbytes / 1e9:.2f} GB"
    )
    shape = array.shape

    if len(shape) >= 3:
        chunks = list(array.chunks)
        assert len(chunks) == len(shape)
        for i in range(1, len(chunks)):
            chunks[i] = shape[i]
        shards = chunks
        shards[0] = min(shape[0], shards[0] * shards_factor)
        shards = tuple(shards)
    else:
        chunks = array.chunks
        shards = None
    attrs = dict(array.attrs)
    if "_ARRAY_DIMENSIONS" in array.attrs:
        dim_names = attrs.pop("_ARRAY_DIMENSIONS")
    else:
        dim_names = None
    array_v3 = group_v3.create_array(
        key,
        shape=array.shape,
        dtype=array.dtype,
        chunks=chunks,
        shards=shards,
        compressors=None,
        attributes=attrs,
        dimension_names=dim_names,
    )
    # Copy data in chunks along the first dimension
    chunk_size = 10  # Adjust this based on available memory
    for start in range(0, shape[0], chunk_size):
        end = min(start + chunk_size, shape[0])
        print(f"  Copying chunk {start}:{end} of {shape[0]}")
        array_v3[start:end] = array[start:end]


print(group_v3.info_complete())
zarr.consolidate_metadata(store)
del group_v2, group_v3

import xarray as xr

ds = xr.open_zarr(datav3_path)
print(ds.info())
