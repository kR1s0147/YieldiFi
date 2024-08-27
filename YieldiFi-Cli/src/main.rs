use alloy::providers::{Provider, ProviderBuilder};
use eyre::Result;

#[tokio::main]
async fn main() -> Result<()>{
    let rpc="https://sepolia.infura.io/v3/6518332f09254566878d16571dfb9468".parse()?;

    let addr="0x9CFb08Ed5169990c39E28144c630585b7725c9d5".parse()?;

    let provider=ProviderBuilder::new().on_http(rpc);

    let latestBlock=provider.get_balance(addr).await?;

    println!("{latestBlock}");

    Ok(())
}
