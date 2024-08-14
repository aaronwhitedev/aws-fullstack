import { useEffect } from "react";
import { useRouteError, Link } from "react-router-dom";

function ErrorPage() {
	const error = useRouteError();
	console.error(error);

	useEffect(() => {
		document.title = "Page Not Found";
	}, []);

	return (
		<>
			Page Not Found
			<br />
			<Link className="link" to="/">
				Click Here
			</Link>
			to go home.
		</>
	);
}

export default ErrorPage;
