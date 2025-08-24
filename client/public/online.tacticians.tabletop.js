if (typeof online === 'undefined')
{
	online = {};
}

if (typeof online.tacticians === 'undefined')
{
	online.tacticians = {};
}

if (typeof online.tacticians.tabletop === 'undefined')
{
	online.tacticians.tabletop = {};
}

online.tacticians.tabletop.init =
	function (node_id)
	{
		online.tacticians.tabletop.app =
			Gren.Main.init
			(
				{
					node: document.getElementById(node_id)
				}
			);

		online.tacticians.tabletop.app.ports.local_store.subscribe
		(
			function (json_request)
			{
				var request = JSON.parse(json_request);

				online.tacticians.tabletop.local_store(request.key, request.value);
			}
		);

		online.tacticians.tabletop.app.ports.local_read.subscribe
		(
			function (json_request)
			{
				var request = JSON.parse(json_request);

				return online.tacticians.tabletop.local_read(request.key);
			}
		);

		online.tacticians.tabletop.app.ports.local_delete.subscribe
		(
			function (json_request)
			{
				var request = JSON.parse(json_request);

				online.tacticians.tabletop.local_delete(request.key);
			}
		);

		online.tacticians.tabletop.app.ports.local_delete_all.subscribe
		(
			online.tacticians.tabletop.local_delete_all
		);

		online.tacticians.tabletop.app.ports.url_param_store.subscribe
		(
			function (json_request)
			{
				var request = JSON.parse(json_request);

				online.tacticians.tabletop.url_param_store(request.key, request.value);
			}
		);

		online.tacticians.tabletop.app.ports.url_param_read.subscribe
		(
			function (json_request)
			{
				var request = JSON.parse(json_request);

				return online.tacticians.tabletop.url_param_read(request.key);
			}
		);

		online.tacticians.tabletop.app.ports.url_param_read_all.subscribe
		(
			online.tacticians.tabletop.url_param_read_all
		);

		online.tacticians.tabletop.app.ports.url_param_delete.subscribe
		(
			function (json_request)
			{
				var request = JSON.parse(json_request);

				online.tacticians.tabletop.url_param_delete(request.key);
			}
		);

		online.tacticians.tabletop.app.ports.url_param_delete_all.subscribe
		(
			online.tacticians.tabletop.url_param_delete_all
		);

		online.tacticians.tabletop.app.ports.set_page_title.subscribe
		(
			online.tacticians.tabletop.set_page_title
		);
	};

online.tacticians.tabletop.local_store =
	function (key, value)
	{
		localStorage.setItem(key, value);
	};

online.tacticians.tabletop.local_read =
	function (key)
	{
		return localStorage.getItem(key);
	};

online.tacticians.tabletop.local_read_all =
	function ()
	{
		return JSON.stringify(localStorage);
	};

online.tacticians.tabletop.local_delete =
	function (key)
	{
		localStorage.removeItem(key);
	};

online.tacticians.tabletop.local_delete_all =
	function (key)
	{
		localStorage.clear();
	};

online.tacticians.tabletop.url_param_store =
	function (key, value)
	{
		const url = new URL(location);

		url.searchParams.set(key, value);

		history.pushState({}, "", url);
	};

online.tacticians.tabletop.url_param_read =
	function (key)
	{
		const url = new URL(location);

		return url.searchParams.get(key);
	};

online.tacticians.tabletop.url_param_read_all =
	function ()
	{
		const url = new URL(location);

		return JSON.stringify(url.searchParams);
	};

online.tacticians.tabletop.url_param_delete =
	function (key)
	{
		const url = new URL(location);

		url.searchParams.delete(key);

		history.pushState({}, "", url);
	};

online.tacticians.tabletop.url_param_delete_all =
	function ()
	{
		const url = new URL(location);

		while (url.searchParams.size > 0)
		{
			url.searchParams.delete(url.searchParams.keys().next().value);
		}

		history.pushState({}, "", url);
	};

online.tacticians.tabletop.set_page_title =
	function (value)
	{
		document.title = value;
	};
