import { useEffect, useState } from "react";

function Home() {
	const [books, setBooks] = useState<string[]>([]);
	const [displayMessage, setDisplayMessage] = useState({ status: "", message: "" });

	useEffect(() => {
		document.title = "Home";

		(async () => {
			try {
				const resp = await window.fetch(`${import.meta.env.VITE_API}`);
				const data = await resp.json();
				if (data.error) {
					return setDisplayMessage({ status: "error", message: "Unable to retrieve information" });
				}

				setBooks(data.books);
			} catch (err) {
				return setDisplayMessage({ status: "error", message: "Unable to retrieve information" });
				console.log(err);
			}
		})();
	}, []);

	return (
		<div className="flex justify-center pt-2">
			<div className="2xl:w-1/2 xl:w-3/4 lg:w-4/5 md:p-2 xs:w-full justify-center grid grid-cols-12">
				<div className="w-full md:col-span-8 col-span-12">
					<div className="mx-1">
						<h1 className="text-5xl font-bold font-sans">Welcome</h1>
						<div className="h-7">{displayMessage.message !== "" && <span className={displayMessage.status}>{displayMessage.message}</span>}</div>
						{books &&
							books.map((book: any) => {
								return <div>{book.name}</div>;
							})}
					</div>
				</div>
			</div>
		</div>
	);
}

export default Home;
