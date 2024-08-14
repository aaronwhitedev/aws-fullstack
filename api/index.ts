import { Handler, APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

export const handler: Handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
	return {
		statusCode: 200,
		headers: { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" },
		body: JSON.stringify({ error: false, books: [{ name: "Clean Code" }, { name: "The Pragmatic Programmer" }] }),
	};
};
