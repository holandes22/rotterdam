var webpack = require("webpack");
var merge = require("webpack-merge");
var CopyWebpackPlugin = require("copy-webpack-plugin");
var ExtractTextPlugin = require("extract-text-webpack-plugin");


var common = {
  module: {
    loaders: [
      {
        test: /\.js$/,
        exclude: [/node_modules/],
        loader: "babel",
        query: {
          presets: ["es2015"]
        }
      },
      {
        test: /\.css$/,
        loader: ExtractTextPlugin.extract("style", "css")
      },
      {
        test: /\.scss$/,
        loader: "style-loader!css-loader!sass-loader"
      },
      {
        test: /\.png$/,
        loader: 'file'
      },
      {
        test: /\.(ttf|eot|svg)(\?[\s\S]+)?$/,
        loader: "file"
      },
      {
        test: /\.woff2?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: "url"
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: "elm-webpack?cwd=" + __dirname + "/web/elm"
      },
    ],
    noParse: [/\.elm$/]
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin({
      compress: {warnings: false},
      output: {comments: false}
    })
  ]
};

module.exports = [
  merge(common, {
    entry: [
      "normalize.css",
      "purecss/build/pure.css",
      "font-awesome-loader",
      "./web/static/app/app.scss",
      "./web/static/app/app.js"
    ],
    output: {
      path: "./priv/static",
      filename: "js/app.js"
    },
    resolve: {
      modules: [
        "node_modules",
        __dirname + "/web/static/app"
      ]
    },
    plugins: [
      new CopyWebpackPlugin([{ from: "./web/static/assets" }]),
      new ExtractTextPlugin("css/app.css")
    ]
  })
];
